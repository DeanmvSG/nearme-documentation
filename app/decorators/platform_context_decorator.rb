class PlatformContextDecorator

  delegate :white_label_company, :instance, :theme, :partner, :domain, :white_label_company_user?,
           :platform_context_detail, :secured_constraint, :latest_products, to: :platform_context

  delegate :tagline, :support_url, :blog_url, :twitter_url, :twitter_handle, :facebook_url, :gplus_url, :address,
           :phone_number, :site_name, :description, :support_email, :meta_title, :pages, :hero_image, :logo_image,
           :favicon_image, :icon_image, :icon_retina_image, :call_to_action, :is_company_theme?, :content_holders, to: :theme

  delegate :bookable_noun, :lessor, :lessee, :name, :buyable?, :bookable?,
           :transactable_types, :product_types, :project_types, :service_types, :wish_lists_icon_set,
           :seller_attachments_enabled?, :wish_lists_enabled?, to: :instance

  liquid_methods :lessors

  def initialize(platform_context)
    @platform_context = platform_context
  end

  def single_type?
    self.transactable_types.count == 1
  end

  def to_liquid
    @platform_context_drop ||= PlatformContextDrop.new(self)
  end

  def lessors
    lessor.pluralize
  end

  def lessees
    lessee.pluralize
  end

  def host
    domain.name
  end

  def build_url_for_path(path)
    raise "Expected relative path, got #{path}" unless path[0] == '/'
    "https://#{host}#{path}"
  end

  def support_email_for(error_code)
    support_email_splited = self.support_email.split('@')
    support_email_splited.join("+#{error_code}@")
  end

  def contact_email
    @platform_context.theme.contact_email_with_fallback
  end

  def search_by_keyword_placeholder
    I18n.t('homepage.search_field_placeholder.full_text')
  end

  def platform_context_detail_key
    @platform_context_detail_key = "#{platform_context_detail.class.to_s.downcase}_#{platform_context_detail.id}"
  end

  def normalize_timestamp(timestamp)
    timestamp.try(:utc).try(:to_s, :number)
  end

  def stripe_public_key
    # TODO - remove stripe public key as it's not used anymore
    PaymentGateway::StripePaymentGateway.first.settings[:public_key] rescue nil
  end

  def supported_payout_via_ach?
    Billing::Gateway::Processor::Outgoing::ProcessorFactory.supported_payout_via_ach?(self.instance)
  end

  def bookable_nouns
    @bookable_nouns ||= transactable_types.map { |tt| tt.translated_bookable_noun }.to_sentence(last_word_connector: I18n.t('general.or_spaced'))
  end

  def bookable_nouns_plural
    @bookable_nouns_plural ||= transactable_types.map { |tt| tt.translated_bookable_noun(10) }.to_sentence(last_word_connector: I18n.t('general.or_spaced'))
  end

  def homepage_content
    Liquid::Template.parse(theme.homepage_content).render(nil, filters: [LiquidFilters]).html_safe
  end

  def facebook_key
    Rails.env.development? || Rails.env.test? ? DesksnearMe::Application.config.facebook_key : instance.facebook_consumer_key
  end


  private

  def platform_context
    @platform_context
  end

end
