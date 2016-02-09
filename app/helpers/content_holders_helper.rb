module ContentHoldersHelper

  INJECT_PAGES = {
    'listings/reservations#review' => 'checkout',
    'buy_sell_market/checkout#show' => 'checkout',
    'buy_sell_market/cart#index' => 'cart',
    'dashboard/user_reservations#booking_successful' => 'checkout_success',
    'dashboard/orders#success' => 'checkout_success',
    'buy_sell_market/products#show' => 'service/product_page',
    'listings#show' => 'service/product_page',
    'search#index' =>'search_results'
  }


  def platform_context
    @platform_context_view ||= PlatformContext.current.decorate
  end

  def inject_pages_collection
    INJECT_PAGES.values.uniq.map do |path|
      [path.humanize, path]
    end + [['Any page', 'any_page']]
  end

  def content_holder_cache_key(name)
    "theme.#{platform_context.theme.id}.content_holders.names.#{name}"
  end

  def content_holder_for_path_cache_key(path = nil)
    "theme.#{platform_context.theme.id}.content_holders.paths.#{path}"
  end

  def inject_content_holder(name)
    if holder = get_content_holder(name)
      raw holder
    end
  end

  def get_content_holders_for_path(path)
    Rails.cache.fetch content_holder_for_path_cache_key(path), expires_in: 12.hours do
      platform_context.content_holders.enabled.by_inject_pages(path)
    end
  end

  def get_content_holder(name)
    Rails.cache.fetch content_holder_cache_key(name), expires_in: 12.hours do
      if content_holder = platform_context.content_holders.enabled.no_inject_pages.no_position(['meta', 'head_bottom']).find_by_name(name)
        content_holder.content
      end
    end
  end

end
