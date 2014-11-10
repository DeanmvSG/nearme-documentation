# Class responsible for encapsulating multi-tenancy logic.
#
# PlatformContext for normal requests is set based on current domain. Information about current platform
# is accessible via class method current(). It is thread-safe, as long as we make sure the context is cleared
# between requests. For jobs invoked in background, we pass platform_context_detail [ class and id ], which allows us
# to retreive the context. We also have to make sure the context is set for each job [ nil is valid, so if we don't need context
# in certain job, we have to set it nil! ]. In some parts of the app, we have to overwrite default platform context. For example for
# admin, we don't care on which domain we are - we are admins and we should have access to everything. We can achieve this by
# manually set PlatformContext.current to nil via current= class method [ PlatformContext.current = nil ].
#
# PlatformContext is mainly used to display the right theme and text in UI, emails, and to ensure proper scoping [ i.e. if we have
# two instances, desksnear.me and boatsnear.you, we don't want to display any boats on desksnear.me, and we don't want to display
# and desks at boatsnear.you.
#
# To ensure proper scoping, there are two helper modules, which are added to any ActiveRecord classes during initializations.
# These are PlatformContext::ForeignKeysAssigner and PlatformContext::DefaultScope. The first one ensures that db columns with foreign
# keys to platform_context models [ like instance, partner, company ] are properly set. The second one ensures we retreive from db
# only records that belong to current platform context. See these classes at app/models/platform_context/ for more information.

class PlatformContext
  DEFAULT_REDIRECT_CODE = 302
  NEAR_ME_REDIRECT_URL = 'http://near-me.com/?domain_not_valid=true'

  attr_reader :domain, :platform_context_detail, :instance_type, :instance, :theme, :domain,
    :white_label_company, :partner, :request_host, :blog_instance

  class_attribute :root_secured
  self.root_secured = Rails.application.config.root_secured

  def self.current
    Thread.current[:platform_context]
  end

  def self.current=(platform_context)
    Thread.current[:platform_context] = platform_context
    after_setting_current_callback(platform_context) if platform_context.present?
  end

  def self.after_setting_current_callback(platform_context)
    ActiveRecord::Base.establish_connection(platform_context.instance.db_connection_string) if platform_context.instance.db_connection_string.present?
    Transactable.clear_custom_attributes_cache
    UserInstanceProfile.clear_custom_attributes_cache
  end

  def self.scope_to_instance
    Thread.current[:force_scope_to_instance] = true
  end

  def self.scoped_to_instance?
    Thread.current[:force_scope_to_instance]
  end

  def self.clear_current
    Thread.current[:platform_context] = nil
    Thread.current[:force_scope_to_instance] = nil
  end

  def initialize(object = nil)
    case object
    when String
      initialize_with_request_host(object)
    when Partner
      initialize_with_partner(object)
    when Company
      initialize_with_company(object)
    when Instance
      initialize_with_instance(object)
    else
      raise "Can't initialize PlatformContext with object of class #{object.class}"
    end
  end

  def secured_constraint
    if domain = @instance.domains.secured.first
      {host: domain.name, protocol: 'https', only_path: false}
    else
      {host: Rails.application.routes.default_url_options[:host], protocol: 'https', only_path: false}
    end
  end

  def secured?
    (root_secured?) || @domain.try(:secured?)
  end

  def root_secured?
    self.class.root_secured
  end

  def initialize_with_request_host(request_host)
    @request_host = remove_port_from_hostname(request_host)
    initialize_with_domain(fetch_domain)
  end

  def initialize_with_domain(domain)
    if domain.present? && domain.white_label_enabled? && domain.target.present?
      @domain = domain
      if @domain.white_label_company?
        initialize_with_company(@domain.target)
      elsif @domain.instance?
        initialize_with_instance(@domain.target)
      elsif @domain.partner?
        initialize_with_partner(@domain.target)
      end
    end
    self
  end

  def initialize_with_partner(partner)
    @partner = partner
    @platform_context_detail = @partner
    @instance = @partner.instance
    @instance_type = @instance.instance_type
    @theme = @partner.theme.presence
    @domain ||= @partner.domain
    self
  end

  def initialize_with_company(company)
    if company.white_label_enabled
      @white_label_company = company
      @platform_context_detail = @white_label_company
      @instance = company.instance
      @instance_type = @instance.instance_type
      @theme = company.theme
      @domain ||= company.domain
    else
      if company.partner.present?
        initialize_with_partner(company.partner)
      else
        initialize_with_instance(company.instance)
      end
    end
    self
  end

  def initialize_with_instance(instance)
    @instance = instance
    @instance_type = @instance.instance_type
    @platform_context_detail = @instance
    @theme = @instance.theme
    @domain ||= @instance.default_domain
    self
  end

  def white_label_company_user?(user)
    return true  if white_label_company.nil?
    return false if user.nil?
    user.companies_metadata.try(:include?, white_label_company.id)
  end

  def decorate
    @decorator ||= PlatformContextDecorator.new(self)
  end

  def should_redirect?
    return true unless @domain
    return true if @domain.redirect?
    @domain.name != @request_host
  end

  def redirect_url
    return NEAR_ME_REDIRECT_URL unless @domain
    @domain.redirect? ? @domain.redirect_to : @domain.url
  end

  def redirect_code
    return DEFAULT_REDIRECT_CODE unless @domain
    return DEFAULT_REDIRECT_CODE if @domain.redirect_code.blank?
    @domain.redirect_code
  end

  def to_h
    { request_host: @request_host }.merge(
      Hash[instance_variables.
           reject{|iv| iv.to_s == '@request_host' || iv.to_s == '@decorator'}.
           map{|iv| iv.to_s.gsub('@', '')}.
           map{|iv| ["#{iv}_id", send(iv).try(:id)]}]
    )
  end

  def latest_products(number = 6)
    products = Spree::Product.searchable.order('created_at desc').limit(number).all
    while products.size < number && !products.size.zero?
      products += products
    end
    products.first(number)
  end

  private

  def fetch_domain
    Domain.where_hostname(@request_host)
  end

  def remove_port_from_hostname(hostname)
    hostname.split(':').first
  end

end
