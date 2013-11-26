class PlatformContextDecorator

  delegate :white_label_company, :instance, :theme, :partner, :white_label_company_user?, :to => :platform_context

  delegate :contact_email, :tagline, :support_url, :blog_url, :twitter_url, :facebook_url, :gplus_url, :address,
    :phone_number, :site_name, :description, :support_email, :compiled_stylesheet, :meta_title, :pages, :logo_image, :to => :theme

  delegate :bookable_noun, :lessor, :lessee, :name, :is_desksnearme?, :to => :instance

  def initialize(platform_context)
    @platform_context = platform_context
  end

  def compiled_stylesheet_url
    compiled_stylesheet.present? ? compiled_stylesheet.url : nil
  end

  def to_liquid
    @platform_context_drop ||= PlatformContextDrop.new(self)
  end

  private

  def platform_context
    @platform_context
  end

end
