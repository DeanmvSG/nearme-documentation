class InstanceMailer < ActionMailer::Base
  prepend_view_path EmailResolver.instance
  extend Job::SyntaxEnhancer
  include ActionView::Helpers::TextHelper
  helper :listings, :reservations

  self.job_class = MailerJob
  attr_accessor :platform_context, :email_method

  def mail(options = {})
    @platform_context = PlatformContext.current.decorate
    default_mailer = @platform_context.theme.default_mailer
    lookup_context.class.register_detail(:platform_context) { nil }
    template = options.delete(:template_name) || view_context.action_name
    mailer = options.delete(:mailer) || find_mailer(template: template) || default_mailer
    to = options[:to]
    bcc = options.delete(:bcc) || mailer.bcc || default_mailer.from
    from = options.delete(:from) || mailer.from || default_mailer.from
    subject_locals = options.delete(:subject_locals) || {}
    subject_locals = subject_locals.merge(platform_context: @platform_context)
    subject  = mailer.liquid_subject(subject_locals) || liquid_subject(subject_locals) || options.delete(:subject)
    reply_to = options.delete(:reply_to) || mailer.reply_to
    @user  = User.with_deleted.find_by_email(to.kind_of?(Array) ? to.first : to)
    self.email_method = StackTraceParser.new(caller[0])
    self.email_method = StackTraceParser.new(caller[1]) if ['generate_mail', 'request_rating'].include?(self.email_method.method_name)
    custom_tracking_options  = (options.delete(:custom_tracking_options) || {}).reverse_merge({template: template, campaign: self.email_method.humanized_method_name})

    @mail_type = mail_type
    @mailer_signature = generate_signature
    @unsubscribe_link = unsubscribe_url(signature: @mailer_signature, token: @user.temporary_token) if non_transactional?
    @signature_for_tracking = "&email_signature=#{@mailer_signature}"

    track_sending_email(custom_tracking_options)
    self.class.layout _layout, platform_context: @platform_context

    mixed = super(options.merge!(
      :subject => subject,
      :bcc     => bcc,
      :from    => from,
      :reply_to=> reply_to)) do |format|
        format.html { render(template, platform_context: @platform_context) + get_tracking_code(custom_tracking_options).html_safe }
        format.text { render template, platform_context: @platform_context }
      end

      mixed.add_part(
        Mail::Part.new do
          content_type 'multipart/alternative'
          mixed.parts.reverse!.delete_if {|p| add_part p }
        end
      )

      mixed.content_type 'multipart/mixed'
      mixed.header['content-type'].parameters[:boundary] = mixed.body.boundary
  end

  def liquid_subject(interpolations = {})
    mailer_scope = self.class.mailer_name.tr('/', '.')
    subject = I18n.t(:subject, scope: [mailer_scope, action_name])
    template = Liquid::Template.parse(subject)
    template.render(interpolations.stringify_keys!)
  end

  def mail_type
    DNM::MAIL_TYPES::BULK
  end

  def transactional?
    mail_type == DNM::MAIL_TYPES::TRANSACTIONAL
  end

  def non_transactional?
    mail_type == DNM::MAIL_TYPES::NON_TRANSACTIONAL
  end

  private

  def instance_prefix(text)
    text.prepend "[#{instance_name}] "
    text
  end

  def find_mailer(options = {})
    default_options = { template: view_context.action_name }
    options = default_options.merge!(options)

    details = {platform_context: [PlatformContext.current], handlers: [:liquid], formats: [:html, :text]}
    template_name = options[:template]
    template_prefix = view_context.lookup_context.prefixes.first

    template = EmailResolver.instance.find_mailers(template_name, template_prefix, false, details).first

    return template
  end

  def get_tracking_code(custom_tracking_options)
    event_tracker.pixel_track_url("Email Opened", custom_tracking_options)
  end

  def event_tracker
    @mixpanel_wrapper ||= AnalyticWrapper::MixpanelApi.new(
      AnalyticWrapper::MixpanelApi.mixpanel_instance(),
      :current_user       => @user,
      :request_details    => { :current_instance_id => @platform_context.instance.id }
    )
    @event_tracker ||= Analytics::EventTracker.new(@mixpanel_wrapper, AnalyticWrapper::GoogleAnalyticsApi.new(@user))
    @event_tracker
  end

  def track_sending_email(custom_tracking_options)
    event_tracker.email_sent(custom_tracking_options)
  end

  def generate_signature
    verifier = ActiveSupport::MessageVerifier.new(DesksnearMe::Application.config.secret_token)
    verifier.generate("#{self.class.name.underscore}/#{self.email_method.method_name.underscore}")
  end

  def instance_name
    PlatformContext.current.instance.name
  end

  def theme_contact_email
    PlatformContext.current.theme.contact_email
  end

  def instance_bookable_noun
    PlatformContext.current.instance.bookable_noun
  end
end
