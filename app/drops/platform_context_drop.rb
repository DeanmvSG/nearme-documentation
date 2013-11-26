class PlatformContextDrop < BaseDrop
  delegate :name, :bookable_noun, :pages, :platform_context, :is_desksnearme, :blog_url, :twitter_url, :lessor, :lessee,
    :facebook_url, :address, :phone_number, :gplus_url, :site_name, :support_url, :logo_image, :to => :platform_context_decorator

  def initialize(platform_context_decorator)
    @platform_context_decorator = platform_context_decorator
  end

  def bookable_noun_plural
    @platform_context_decorator.bookable_noun.pluralize
  end

  def logo_url
    @platform_context_decorator.logo_image.url || "https://s3.amazonaws.com/desksnearme.production/uploads/theme/logo_retina_image/1/logo_2x.png"
  end

  private

  def platform_context_decorator
    @platform_context_decorator
  end
end

