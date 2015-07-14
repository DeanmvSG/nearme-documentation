class PlatformContextDrop < BaseDrop

  attr_reader :platform_context_decorator

  # name
  #   name of the marketplace
  # bookable_noun
  #   name of representing the bookable object transactable on the marketplace as a string
  # pages
  #   array of pages created for this marketplace by the marketplace admin
  # blog_url
  #   url to the blog for this marketplace
  # twitter_url
  #   the twitter address for this marketplace
  # lessor
  #   name of the person which offers the service
  # lessors
  #   pluralized name of the person which offers the service
  # lessee
  #   name of the person which uses (purchases) the service
  # lessees
  #   pluralized name of the person which uses (purchases) the service
  # searcher_type
  #   type of search for this marketplace as set by the marketplace admin from the marketplace administration interface
  # search_by_keyword_placeholder
  #   placeholder text for searching by keyword; usually is "Search by keyword" unless a translation key has been added for this string by the marketplace admin
  # fulltext_search?
  #   returns true if the searcher_type for this marketplace is either "fulltext" or "fulltext_category"
  # facebook_url
  #   url for the Facebook page of this marketplace
  # address
  #   address of the company operating the marketplace as a string
  # phone_number
  #   phone_number of the company operating the marketplace as a string
  # gplus_url
  #   url to the Google Plus page of the marketplace
  # site_name
  #   name of the marketplace
  # support_url
  #   url (or mailto: link) to the support page for this marketplace
  # support_email
  #   email address of the support department of this marketplace
  # logo_image
  #   logo image object containing the logo image for this marketplace
  #   logo_image.url returns the url of this logo_image
  # tagline
  #   tagline for this marketplace as string
  # search_field_placeholder
  #   placeholder text for search fields
  # homepage_content
  #   HTML for the homepage (theme) as set in the admin section by the marketplace admin
  # fulltext_geo_search?
  #   returns true if searcher_type for the marketplace is "fulltext_geo"
  # is_company_theme?
  #   returns true if the theme belongs to a company
  # call_to_action
  #   call to action text as set for this theme
  # latest_products
  #   array of the latest product objects created for this marketplace
  # buyable?
  #   returns true if the marketplace has any product types defined
  # bookable?
  #   returns true if the marketplace has any service types defined
  # transactable_types
  #   array of transactable_types (service types) for this marketplace
  # product_types
  #   array of product types for this instance
  # bookable_nouns
  #   text containing the bookable nouns as a sentence (e.g. "desk or table or room")
  # bookable_nouns_plural
  #   text containing the bookable nouns as a sentence (e.g. "desks or tables or rooms")
  # search_input_name
  #   HTML name of the input element to be used in search pages
  delegate :name, :bookable_noun, :pages, :platform_context, :blog_url, :twitter_url, :lessor, :lessors, :lessee, :lessees, :searcher_type, :search_by_keyword_placeholder, :fulltext_search?,
    :facebook_url, :address, :phone_number, :gplus_url, :site_name, :support_url, :support_email, :logo_image, :tagline, :homepage_content, :fulltext_geo_search?,
    :is_company_theme?, :call_to_action, :latest_products, :buyable?, :bookable?, :transactable_types, :product_types, :bookable_nouns, :bookable_nouns_plural, :search_input_name, to: :platform_context_decorator


  def initialize(platform_context_decorator)
    @platform_context_decorator = platform_context_decorator
    @instance = platform_context_decorator.instance
  end

  # search field placeholder as a string
  def search_field_placeholder
    @instance.search_text.blank? ? @platform_context_decorator.search_field_placeholder : @instance.search_text
  end

  # name of the bookable item for this marketplace (plural) as a string
  def bookable_noun_plural
    @platform_context_decorator.bookable_noun.pluralize
  end

  # url to the logo image
  def logo_url
    @platform_context_decorator.logo_image.url || image_url("assets/platform_home/logo-01-dark.png").to_s
  end

  # url to the "checked badge" image
  def checked_badge_url
    image_url("themes/buy_sell/check.png")
  end

  # root path for this marketplace
  def root_path
    routes.root_path
  end

  # full url to the root of the marketplace
  def host
    "http://#{platform_context_decorator.host}"
  end

  # full url to the root of the server hosting the assets (images, javascripts, stylesheets etc.)
  def asset_host
    Rails.application.config.action_controller.asset_host || host
  end

  # hex value (as string) for the color black as set for this marketplace, or the default
  def color_black
    theme_color('black')
  end

  # hex value (as string) for the color blue as set for this marketplace, or the default
  def color_blue
    theme_color('blue')
  end

  # array of category objects for this marketplace's service types
  def service_categories
    transactable_types.services.map{ |t| t.categories.searchable.roots }.flatten
  end

  # array of category objects for this marketplace's product types
  def product_categories
    product_types.map{ |t| t.categories.searchable.roots }.flatten
  end

  # returns true if this marketplace has multiple service types defined
  def multiple_transactable_types?
    transactable_types.many?
  end

  # url for editing the notification preferences
  def unsubscribe_url
    urlify(routes.edit_dashboard_notification_preferences_path)
  end

  # returns true if the option to display the date pickers
  # is set for this marketplace
  def display_date_pickers?
    @instance.date_pickers
  end

  # returns the type of select for this marketplace to be used when 
  # multiple service types are defined (e.g. radio, dropdown etc.)
  def tt_select_type
    @instance.tt_select_type
  end

  # returns the container class and input size to be used for the search area
  # of the marketplace's homepage
  def calculate_elements
    sum = 2 #search button
    sum += 4 if display_date_pickers?
    sum += 2 if multiple_transactable_types? && tt_select_type != 'radio'
    sum += 3 if category_search?
    input_size = 12 - sum #span12
    input_size /= 2 if fulltext_geo_search? #two input fields
    container = input_size == 2 ? "span12" : "span10 offset1"
    [container, input_size]
  end

  # returns the container class to be used for the search area
  # of the marketplace's homepage
  def calculate_container
    calculate_elements[0]
  end

  # returns the input size to be used for the search area of the
  # marketplace's homepage
  def calculate_input_size
    "span#{calculate_elements[1]}"
  end

  # returns true if the set marketplace searcher_type is "fulltext_category"
  def fulltext_category_search?
    @instance.searcher_type == 'fulltext_category'
  end

  # returns true if the set marketplace searcher_type is "geo_category"
  def geo_category_search?
    @instance.searcher_type == 'geo_category'
  end

  # returns true if the marketplace searcher_type has been set to either
  # "fulltext_category" or "geo_category"
  def category_search?
    fulltext_category_search? || geo_category_search?
  end

  private

  def theme_color(color)
    @platform_context_decorator.theme.hex_color(color).presence || Theme.hexify(Theme.default_value_for_color(color))
  end

end
