# frozen_string_literal: true
require 'googl'
require 'sanitize'

module LiquidFilters
  include MoneyRails::ActionViewExtension
  include CurrencyHelper
  include ActionView::Helpers::NumberHelper
  include WillPaginate::ViewHelpers
  include ActionView::Helpers::UrlHelper
  include ActionView::RecordIdentifier
  include ActionView::Helpers::DateHelper
  include LiquidFormHelpers

  # @return [String] url shortened using the Google service
  # @param url [String] the original url to be shortened
  def shorten_url(url)
    if DesksnearMe::Application.config.googl_api_key.present?
      Googl.shorten(url, nil, DesksnearMe::Application.config.googl_api_key).short_url
    else
      Googl.shorten(url).short_url
    end
  # We use Exception to silence exceptions already encountered coming from the Goo.gl service;
  # a MarketplaceLogger error will be logged
  rescue Exception => e
    if Rails.env.production?
      MarketplaceLogger.error('Url Shortening Error', e.to_s + ' :: ' + url, raise: false)
      ''
    else
      'http://limitreached'
    end
  end

  # Sets the @no_footer variable to true to affect further rendering (i.e. the footer
  #   will not be rendered)
  # @return [nil]
  def no_footer!
    @no_footer = true
  end

  # @return [Hash] returns data
  # @param query_string [String] graphql query
  # @param params [Hash, nil] variables used in query
  # @param current_user [User]
  def query(query_string, params = {}, current_user = nil)
    ::Graph.execute_query(
      query_string,
      variables: params,
      context: {
        current_user: current_user
      }
    )
  end

  # @return [String, nil] returns class_name (by default 'active') if the first
  #   two arguments are equal, nil otherwise
  # @param arg1 [String] any string - will be used for comparison with the other string
  # @param arg2 [String] any string - will be used for comparison with the other string
  def active_class(arg1, arg2, class_name = 'active')
    class_name if arg1 == arg2
  end

  # @return [Boolean] whether the array includes the element given
  # @param array [Array] array of elements where we look into
  # @param el [Object] we will look for this element inside the array
  def is_included_in_array(array, el)
    array.include?(el)
  end

  # @return [Array] result contains all elements from both arrays.
  # @param array [Array] base array
  # @param el [Object] we will transform object into array and add it to the other. Method
  # is called soft, because it will not crash when nil is provided as argument
  def soft_concat(array, obj)
    Array(array) + Array(obj)
  end

  # @return [Array<Array<Object>>] the original array split into groups having the size
  #   specified by the second parameter (an array of arrays)
  # @param array [Array<Object>] array to be split into groups
  # @param integer [Integer] the size of each group the array is to be split into
  def in_groups_of(array, integer)
    array.in_groups_of(integer)
  end

  # @return [Hash<MethodResult => Array<Object>>] the original array grouped by method
  #   specified by the second parameter
  # @param objects [Array<Object>] array to be grouped
  # @param method [String] method name to be used to group Objects
  def group_by(objects, method)
    objects.group_by(&method.to_sym)
  end

  # @return [String] pluralized version of the input string
  # @param string [String] string to be pluralized
  # @param count [Number] optional count number based on which string will be pluralized or singularized
  def pluralize(string, count = 2)
    count == 1 ? string.try(:singularize) : string.try(:pluralize)
  end

  # @return [Array<Object>] array from which nil values are removed
  # @param array [Array<Object>] array from which to remove nil values
  def compact(array)
    array.compact
  end

  # @return [Array<Object>] array to which we add the item given as the second parameter
  # @param array [Array<Object>] array to which we add a new element
  # @param item [Object] item we add to the array
  def add_to_array(array, item)
    Array(array.presence).push(item)
  end

  # @return [Array<Object>] the input array rotated by a number of times given as the second
  #   parameter; [1,2,3,4] rotated by 2 gives [3,4,1,2]
  # @param array [Array<Object>] array to be rotated
  # @param count [Integer] number of times to rotate the input array
  def rotate(array, count = 1)
    array.rotate(count)
  end

  # @return [String, nil] path to the first searchable listing for the location given as
  #   parameter; nil if no such listing can be found
  # @param location [LocationDrop] location object whose first listing path is extracted
  # @todo Investigate/remove unused _transactable_type parameter?
  def location_path(_transactable_type, location)
    return '' if location.blank?
    location.listings.searchable.first.try(:decorate).try(:show_path)
  end

  # @return [Hash{String => String}] hash of the form !{ 'price' => '$20', 'period' => 'day' } price is a formatted lowest price
  #   for the object given as parameter (without cents, with currency included); does not include additional charges and
  #   service guest fee; for the period, the translation key 'search.per_unit_price' is used with the 'unit' being "search.#{pricing.unit}"
  #   pricing.unit is the actual unit of the pricing (e.g. day, hour, etc.)
  # @param object [LocationDrop, TransactableDrop] object whose price we want to display
  # @param lgpricing_filters [Array<String>] array of pricing type filters (e.g. ["1_day", "1_hour"])
  #   usually passed from the search page
  def lowest_price_without_cents_with_currency(object, lgpricing_filters = [])
    get_lowest_price_with_options(object, lgpricing_filters)
  end

  # @return [Hash{String => String}] hash of the form !{ 'price' => '$20', 'period' => 'day' } price is a formatted lowest full price
  #   for the object given as parameter (without cents, with currency included); includes additional charges and service guest fee;
  #   for the period, the translation key 'search.per_unit_price' is used with the 'unit' being "search.#{pricing.unit}"
  #   pricing.unit is the actual unit of the pricing (e.g. day, hour, etc.)
  # @param object [LocationDrop, TransactableDrop] object whose price we want to display
  # @param lgpricing_filters [Array<String>] array of pricing type filters (e.g. ["1_day", "1_hour"])
  #   usually passed from the search page
  def lowest_full_price_without_cents_with_currency(object, lgpricing_filters = [])
    get_lowest_price_with_options(object, lgpricing_filters, full_price: true)
  end

  # @return [Hash{String => String}] hash of the form !{ 'price' => '$20', 'period' => 'day' } price is a formatted lowest full price
  #   for the object given as parameter (with cents, with currency included); includes additional charges and service guest fee;
  #   for the period, the translation key 'search.per_unit_price' is used with the 'unit' being "search.#{pricing.unit}"
  #   pricing.unit is the actual unit of the pricing (e.g. day, hour, etc.)
  # @param object [LocationDrop, TransactableDrop] object whose price we want to display
  # @param lgpricing_filters [Array<String>] array of pricing type filters (e.g. ["1_day", "1_hour"])
  #   usually passed from the search page
  def lowest_full_price_with_cents_with_currency(object, lgpricing_filters = [])
    get_lowest_price_with_options(object, lgpricing_filters, full_price: true, with_cents: true)
  end

  def get_lowest_price_with_options(object, lgpricing_filters, options = {})
    lgpricing_filters ||= []

    pricing = if options[:full_price]
                object.lowest_full_price(lgpricing_filters)
              else
                object.lowest_price(lgpricing_filters)
              end

    if pricing.nil? || pricing.is_free_booking?
      { 'free' => true }
    else
      if options[:with_cents]
        { 'price' => price_with_cents_with_currency(pricing.price) }
      else
        { 'price' => price_without_cents_with_currency(pricing.price) }
      end.merge('period' => pricing.decorate.units_translation('search.per_unit_price', 'search'))
    end
  end

  # @return [Hash{String => String}] hash of the form !{ 'price' => '$20', 'period' => 'day' } price is a formatted lowest price
  #   for the object given as parameter (with cents, with currency included); does not include additional charges and service guest fee;
  #   for the period, the translation key 'search.per_unit_price' is used with the 'unit' being "search.#{pricing.unit}"
  #   pricing.unit is the actual unit of the pricing (e.g. day, hour, etc.)
  # @param object [LocationDrop, TransactableDrop] object whose price we want to display
  # @param lgpricing_filters [Array<String>] array of pricing type filters (e.g. ["1_day", "1_hour"])
  #   usually passed from the search page
  def lowest_price_with_cents_with_currency(object, lgpricing_filters = [])
    pricing = object.lowest_price(lgpricing_filters)
    if pricing
      { 'price' => price_with_cents_with_currency(pricing.price), 'period' => pricing.decorate.units_translation('search.per_unit_price', 'search') }
    else
      {}
    end
  end

  # @return [Array<String>] array of connection information strings for a user and a listing; for each of the user's friends
  #   (followed users) strings will be generated like so:
  #   If the friend visited the listing, the string 'User.name worked here' will be added.
  #   If the friend is the host of the listing, the string 'User.name is the host' will be added.
  #   If the friend knows the host of the listing the string 'User.name knows the host' will be added.
  #   If a mutual friend (followed user [2] by a user this user follows [1]) visited the listing then the string
  #     'User[1].name knows User[2].name who worked here'
  # @param listing [TransactableDrop] Transactable object used in the generation of the resulting array
  # @param current_user [UserDrop] User object used in the generation of the resulting array
  def connections_for(listing, current_user)
    return [] if current_user.nil? || current_user.friends.count.zero?

    friends = current_user.friends.visited_listing(listing).collect do |user|
      "#{user.name} worked here"
    end

    hosts = current_user.friends.hosts_of_listing(listing).collect do |user|
      "#{user.name} is the host"
    end

    host_friends = current_user.friends_know_host_of(listing).collect do |user|
      "#{user.name} knows the host"
    end

    mutual_visitors = current_user.mutual_friends.visited_listing(listing).collect do |user|
      next unless user.mutual_friendship_source
      "#{user.mutual_friendship_source.name} knows #{user.name} who worked here"
    end

    [friends, hosts, host_friends, mutual_visitors].flatten
  end

  # @return [String] string to be used as a tooltip displaying the connections {LiquidFilters#connections_for}
  #   for a listing and a user; if there are more than 5 connections the translation
  #   'search.list.additional_social_connections' (with the parameter count) is added to the tooltip
  # @param connections [Array<String>] array of connections to be displayed in the tooltip
  # @param size [Integer] the first 'size' connections will be shown in the tooltip
  def connections_tooltip(connections, size = 5)
    difference = connections.size - size
    connections = connections.first(size)
    connections << t('search.list.additional_social_connections', count: difference) if difference > 0
    connections.join('<br />').html_safe
  end

  # @return [String] formatted price using the global price formatting rules
  # @param amount [Numeric] amount to be formatted
  # @param currency [String] currency to be used for formatting
  def pricify(amount, currency = 'USD')
    render_money(amount.to_f.to_money(currency))
  end

  # @return [String] formatted price using the global price formatting rules
  # @param amount [Numeric] amount in cents to be formatted
  # @param currency [String] currency to be used for formatting
  def pricify_cents(amount, currency = 'USD')
    render_money(Money.new(amount.to_i, currency))
  end

  # @return [String] formatted price using the global price formatting rules; the default currency will be used
  # @param money [Numeric] amount to be formatted
  def price_with_cents_with_currency(money)
    render_money(money)
  end

  # @return [String] formatted price using the global price formatting rules; the default currency will be used
  # @param money [Numeric] amount to be formatted
  # @todo Duplicate of price_with_cents_with_currency; they should be unified into one method; requires making
  #   sure we're not affecting marketplaces already using them
  def price_without_cents_with_currency(money)
    render_money(money)
  end

  # @return [String] formatted price using the global price formatting rules; the default currency will be used
  # @param money [Numeric] amount to be formatted
  # This should be used instead of the deprecated price_with_cents_with_currency and price_without_cents_with_currency
  def render_price(money)
    render_money(money)
  end

  # @return [String] formatted price using the global price formatting rules, displayed as negative amount; the default currency will be used
  # @param money [Numeric] amount to be formatted
  def price_with_cents_with_currency_as_cost(money)
    pricify(money.to_f * -1, money.currency)
  end

  # @return [String] url to a placeholder image with the width and height given as parameters
  # @param height [Integer] height of the placeholder image
  # @param width [Integer] width of the placeholder image
  def space_listing_placeholder_path(height, width)
    ActionController::Base.helpers.asset_url(Placeholder.new(height: height.to_i, width: width.to_i).path)
  end

  # @return [String] translated property name; if the property is a basic transactable
  #   attribute the translation key is 'simple_form.labels.transactable.#!{property_name}';
  #   if it's a custom attribute, the translation key is 'transactable_type.#{transactable_type.name}.labels.#!{property_name}'
  # @param property [String] property name to be translated
  # @param target_acting_as_set [TransactableTypeDrop] transactable type that the property belongs to
  def translate_property(property, target_acting_as_set)
    if Transactable::DEFAULT_ATTRIBUTES.include? property
      # These are the hard coded attributes that have their own column on the transactables table
      translate("simple_form.labels.transactable.#{property}")
    else
      # These are the custom attributes added by the MPO
      translate("#{target_acting_as_set.translation_namespace}.labels.#{property}")
    end
  end

  # @return [String] a human readable string derived from the input; capitalizes the first word, turns
  #   underscores into spaces, and strips a trailing '_id' if present. Meant for creating pretty output.
  # @param key [String] input string to be transformed
  def humanize(key)
    key.try(:humanize)
  end

  # @return [String] translation value taken from translations for the key given as parameter
  # @param key [String] translation key
  # @param options [Hash{String => String}] values passed to translation string
  def translate(key, options = {})
    I18n.t(key, options.deep_symbolize_keys)
  end
  alias t translate

  # @return [String, nil] formatted representation of the passed in DateTime object
  # @param datetime [String, DateTime] DateTime object to be formatted; can be a string and it will be converted
  #   to a date
  # @param format [String] the format to be used for formatting the date; default is 'long'; other values can be used:
  #   they are taken from translations, keys are of the form 'time.formats.#!{format_name}'
  def localize(datetime, format = 'long')
    if datetime
      datetime = datetime.to_date if datetime.is_a?(String)
      I18n.l(datetime, format: format.to_sym)
    end
  end
  alias l localize

  # @return [Date] input date/time to which the number_of_days days have been added; use negative values to obtain
  #   a date in the past
  # @param date [Date] date to which we add number_of_days
  # @param number_of_days [Integer] number of days to add to the input date
  def add_to_date(date, number_of_days)
    date + number_of_days.days
  end

  def is_date_in_past(date)
    to_date(date)&.past?
  end

  # @return [String] filtered version of the input text using the marketplace global text filters
  # @param text [String] text to be filtered
  def filter_text(text = '')
    return text unless text.is_a?(String)
    return '' if text.blank?
    if PlatformContext.current.instance.apply_text_filters
      @text_filters ||= TextFilter.pluck(:regexp, :replacement_text, :flags)
      @text_filters.each { |text_filter| text.gsub!(Regexp.new(text_filter[0].strip, text_filter[2]), text_filter[1]) }
      text
    else
      text
    end
  end

  # @return [Integer] minutes since the start of day for the date parsed from the input string
  # @param string [String] string representing a date/time
  def parse_to_minute(string)
    time = parse_time(string)
    hour = time.strftime('%H')
    minute = time.strftime('%M')
    hour.to_i * 60 + minute.to_i
  end

  # @return [String] time in string in HH:MM format 24h clock
  # @param string [Int] number of minutes
  def number_of_minutes_to_time(minutes)
    minutes = minutes.to_i % 1440 # in case we made overnight booking
    hours = (minutes.to_f / 60).floor
    minutes = minutes - (hours * 60)
    "#{'%.2d' % hours}:#{'%.2d' % minutes}"
  end

  # @return [Time] a Time object obtained/parsed from the input object
  # @param string [String] object from which we try to obtain/parse a date object
  def to_time_from_str(string)
    parse_time(string)
  end

  # @return [Date] a Date object obtained/parsed from the input object
  # @param datetime [Date, String, Object] object from which we try to obtain/parse a date object
  def to_date(datetime)
    datetime.try(:to_date)
  end

  # @return [String] sanitized version of the input string; uses a whitelist based approach for allowed elements
  #   and their attributes; the sanitization rules are not currently editable from the marketplace interface
  # @param html [String] HTML string to be sanitized
  def custom_sanitize(html = '')
    return '' if html.blank?
    html = html.to_s
    html = nl2br(html)

    if PlatformContext.current.instance.custom_sanitize_config.present?
      @custom_sanitizer ||= CustomSanitizer.new(PlatformContext.current.instance.custom_sanitize_config)
      @custom_sanitizer.sanitize(html).html_safe
    else
      html
    end
  end

  # @return [String] sanitized version of the input string; uses a strict approach which means it will
  #   strip all HTML and leave only safe text behind
  # @param html [String] HTML string to be sanitized
  def strip_tags(html = '')
    return '' if html.blank?
    html = html.to_s
    @custom_sanitizer ||= CustomSanitizer.new
    @custom_sanitizer.strip_tags(html).html_safe
  end

  # @return [String] replaces newlines in the input string with the <br /> HTML tag
  # @param html [String] HTML string to be processed
  def nl2br(html = '')
    return '' if html.blank?
    html = html.to_s
    html.gsub!("\r\n", '<br />')
    html
  end

  # @return [String] HTML formatted pagination area generated for the input collection with the passed in options
  # @param collection [Array<Object>] array of objects for which we want to generate the pagination area
  # @param options [Hash{String => String}] hash of options for pagination; example:
  #   !{{ listings | pagination_links: param_name: 'services_page', renderer: 'LiquidStyledLinkRenderer' }} will
  #   render the pagination links for listings; services_page will be the name of the page parameters in the browser
  #   and the LiquidStyledLinkRenderer renderer will be used to generate the output HTML
  def pagination_links(collection, options = {})
    opts = {
      controller: @context.registers[:controller],
      renderer: 'LiquidLinkRenderer'
    }.merge(options.symbolize_keys)
    will_paginate collection, opts
  end

  # @return [String] sanitized input string to be used as a meta tag content; uses a strict approach which means it
  #   will strip all HTML and leave only safe text behind; also will replace one or more spaces with a single space
  #   and will strip beginning and ending blank characters
  # @param content [String] string to be sanitized
  def meta_attr(content)
    Sanitize.clean(content).gsub(/\s+/, ' ').strip
  end

  # @return [String] returns the value of the request attribute indicated by the parameter 'method'; e.g.
  #   !{{ 'original_url' | request_parameter }}
  # @param method [String] name of the request attribute to return
  def request_parameter(method)
    @context.registers[:controller].request.send(method.to_sym) if @context.registers[:controller].request.respond_to?(method)
  end

  # @return [String] full url to the image given as a parameter; e.g. 'chevron.jpg' | image_url
  # @param path_to_file [String] file name or relative path to file
  def image_url(path_to_file)
    ActionController::Base.helpers.image_url(path_to_file)
  end

  # @return [String] if the given url is supported, an HTML formatted string containing a video player (inside an iframe)
  #   which will play the video at the given url; otherwise an empty string is returned
  # @param url [String] url to a video on the internet
  def videoify(url = '', options = {})
    return url if url.blank?

    options.symbolize_keys!
    embedder_options = {}
    embedder_options = { iframe_attributes: options } if options.present?

    Videos::VideoEmbedder.new(url, embedder_options).html.html_safe
  end

  # @return [String] JSON formatted string containing a representation of object
  # @param object [Object] object we want a JSON representation of
  def json(object)
    object.to_json
  end

  # @return [String] SHA1 digest of the input object
  # @param object [Object] input object whose digest we want to obtain
  def sha1(object)
    Digest::SHA1.hexdigest object
  end

  # @return [String] if the tag given as a parameter is already in the URL parameter for filtering by
  #   tags it will return a link to the tag which will remove it from the filter; otherwise, if the tag
  #   given as a parameter is not already in the URL parameter for filtering by tags, it will return a
  #   link to the tag which will add this tag to the tag filter
  # @param custom_classes [Array] array of custom classes to be added to the class attribute of the
  #   generated link
  def tag_filter_link(tag, custom_classes = [])
    params = @context.registers[:controller].params
    current_filters = params[:tags].try(:split, ',').presence || []

    if current_filters.try(:include?, tag.slug).presence
      filters_without_current = (current_filters - [tag.slug]).join(',')

      href = "?tags=#{filters_without_current}"
      classes = %w(add selected)
    else
      filters = (current_filters + [tag.slug]).uniq.join(',')

      href = "?tags=#{filters}"
      classes = %w(add)
    end

    classes.push(custom_classes).flatten!.uniq! if custom_classes.present?

    link_to(tag.name, href, class: classes.join(' '))
  end

  # @return [String] renders a form with search boxes for the specified transactable types and with the given options
  # @param tt_names [String] Transactable Type names separated by ','
  # @param class_name [String] additional CSS class name to be used for the search form
  # @param inputs [String] what inputs should be displayed: geolocation, fulltext, categories, datepickers. Separated by ','
  def search_box_for(tt_names, class_name = '', inputs = '')
    names = tt_names.split(',').map(&:strip)
    tt = TransactableType.where(name: names) + InstanceProfileType.where(name: names)
    if tt.any?
      ordered = {}
      tt.map { |searchable| ordered[names.index(searchable.name)] = searchable }
      ordered = ordered.sort.to_h
      @context.registers[:action_view].render 'home/search_box_inputs.html',
                                              transactable_types: ordered.values,
                                              custom_search_inputs: inputs.split(',').map(&:strip),
                                              class_name: class_name + ' search-box-liquid-tag',
                                              transactable_type_picker: ordered.values.many?
    else
      "No Service or Product type with names: #{tt_names}"
    end
  end

  # @return [String] renders a search button in a form for the given transactable type and with the given options
  # @param tt_name [String] Transactable Type name
  # @param class_name [String] additional CSS class name to be used for the search form containing the
  #   search button
  def search_button_for(tt_name, class_name = '')
    if tt = TransactableType.find_by(name: tt_name.strip) || tt = InstanceProfileType.find_by(name: tt_name.strip)
      @context.registers[:action_view].render 'home/search_button_tag.html',
                                              transactable_type: tt,
                                              class_name: class_name + ' search-box-liquid-tag'
    else
      "No Service or Product type with name: #{tt_name}"
    end
  end

  # @return [String] returns a url for the given url helper name and the given arguments; allows to generate
  #   any url inside our platform; e.g. 'user_path' | generate_url: id: 1 generates /users/1
  def generate_url(url_name, *args)
    return "unknown route #{url_name}" unless UrlGenerator.respond_to_missing?(url_name)

    UrlGenerator.public_send(url_name, *args)
  end

  # @return [String] returns a url for the given url helper name and the given arguments with the user temporary token;
  # e.g: 'user_path' | generate_url_with_user_token: current_user, id: 1 generates /users/1?temporary_token=TOKEN_HERE
  def generate_url_with_user_token(url_name, user, args = {})
    generate_url url_name, args.merge(TemporaryTokenAuthenticatable::PARAMETER_NAME => user.source.temporary_token)
  end

  # @return [String] returns a url for the given page slug, which includes user temporary token;
  # e.g: '/account' | url_for_with_token: current_user generates https://example.com/account?temporary_token=TOKEN_HERE
  def url_for_path_with_token(path, user)
    'https://' +
      PlatformContext.current.decorate.host +
      path +
      "?#{TemporaryTokenAuthenticatable::PARAMETER_NAME}=#{user.source.temporary_token}"
  end

  # @return [Time] a time object created from parsing the string representation of time given as input
  # @param time [String] a string representation of time for example 'today', '3 days ago' etc.
  def parse_time(time, format=nil)
    parsed_time = case time
    when /\A\d+\z/, Integer
      Time.zone.at(time.to_i)
    when String
      Chronic.parse(time) || time&.to_time(:local)
    end

    format.blank? ? parsed_time : parsed_time.strftime(format.to_s)
  end

  # @return [Time] a time object created from time in string
  # @param time [String] a string representation of time in hours and minutes, like 4:0 -> 4:00
  # @param zone [String] string representing the time zone
  # 16:3 -> 16:03 etc
  def to_time(time, zone = nil)
    ActiveSupport::TimeZone[zone || Time.zone.name]&.parse(time.to_s)
  end

  # @return [String] the input text marked as 'HTML safe'; this ensures that all HTML content will be output to the
  #   page; otherwise, without this filter the text would be sanitized;
  #   e.g. !{{ @some_variable_with_html_contents | make_html_safe }}
  # @param html [String] input string to mark as 'HTML safe'
  def make_html_safe(html = '')
    html.to_s.html_safe
  end

  # @return [String] input string HTML-escaped; this will return a string whose HTML tags will be visible in
  #   the browser
  # @param value [String] input string to be HTML-escaped
  def raw_escape_string(value)
    CGI.escapeHTML(value.to_s).html_safe
  end

  # @return [Boolean] whether the user has the given object among his wishlisted items
  # @param user [UserDrop] user object
  # @param object [Object] any object; we look among the user's wishlisted items for this object
  def already_favorite(user, object)
    return false unless user.present?
    user.default_wish_list.items.where(wishlistable_id: object.id, wishlistable_type: object.class_name).exists?
  end

  # @return [String] capitalizes all the words and replaces some characters in the string to create
  #   a nicer looking title; it is meant for creating pretty output
  # @param text [String] string to be processed
  def titleize(text)
    text.titleize
  end

  # @return [String] a query string (e.g. "name=Dan&id=1") from a given Hash (e.g. { name: 'Dan', id: 1 })
  # @param hash [Hash{Object => Object}] hash to be "querified"
  def querify(hash)
    hash.to_query
  end

  # @return [Array<ReverseProxyLinkDrop>] array of ReverseProxyLink objects to be used on the url given as a parameter;
  #   they define target destinations for the given url, eg: { current_url | widget_links } or { current_url | widget_links: 'per_page,loc' }
  # @param url [String] url for the ReverseProxyLink objects
  # @param valid_params [String] query params separated by comma used to search proper ReverseProxyLink
  def widget_links(url, valid_params = '')
    return [] unless url.present?
    uri = Addressable::URI.parse(::CGI.unescapeHTML(url.to_str))

    whitelisted_query = Rack::Utils.parse_nested_query(uri.query).slice(*valid_params.split(',')).to_query
    whitelisted_query.prepend('?') if whitelisted_query.present?

    ReverseProxyLink.where(use_on_path: uri.path + whitelisted_query)
  end

  # @return [String] replaces special characters in a string so that it may be used as part of a 'pretty' URL;
  #   the default separator used is '-'; e.g. 'John arrived_foo' becomes 'john-arrived_foo'
  # @param text [String] input string to be 'parameterized'
  # @param separator [String] string to be used as separator in the output string; default is '-'
  def parameterize(text, separator = '-')
    text.parameterize(separator)
  end

  # @return [String] replaces special characters in a string so that it may be used as part of a 'pretty' URL;
  #   e.g. 'John arrived_foo' becomes 'john-arrived-foo'
  # @param text [String] input string to be 'slugified'
  def slugify(text)
    parameterize(text)
      .tr('_', '-')
  end

  # @return [TransactableCollaboratorDrop] transactable collaborator object for the given transactable and user;
  #   this object ties the collaborating user to the transactable
  # @param user [UserDrop] collaborating User object
  # @param transactable [TransactableDrop] Transactable object
  def find_collaborator(user, transactable)
    return false if user.try(:id).blank?
    transactable.transactable_collaborators.where(user: user.id).first
  end

  # @return [Array<Integer>] array of ids of the TransactableCollaborator objects defining collaborations of the
  #   user given as the user parameter, collaborations on Transactable objects (with the state pending, or in_progress
  #   created by the user given as the current_user parameter
  # @param current_user [UserDrop] user object
  # @param user [UserDrop] user object
  def find_collaborators_for_user_transactables(current_user, user)
    user.source.transactable_collaborators.where(transactable_id: current_user.source.created_listings.with_state([:pending, :in_progress]).pluck(:id))
  end

  # @return [Boolean] whether the given user is an approved transactable collaborator of the Transactable given as the parameter
  # @param user [UserDrop] user object
  # @param transactable [TransactableDrop] transactable object
  def is_approved_collaborator(user, transactable)
    return false if user.try(:id).blank?
    transactable.approved_transactable_collaborators.where(user: user.id).exists?
  end

  # @return [Integer] total number of entries for the paginated collection of items passed in
  # @param will_paginate_collection [WillPaginate::Collection] paginated collection of items
  def total_entries(will_paginate_collection)
    will_paginate_collection.total_entries
  end

  # @return [Array<OrderDrop>] array of orders for transactable, belonging to user, ordered
  #   descending by the creation date
  # @param user [UserDrop] user whose orders we want to show
  # @param transactable [TransactableDrop] orders are for this transactable
  def get_enquirer_draft_orders(user, transactable)
    transactable.line_item_orders.where(user_id: user.id).order('created_at ASC')
  end

  # @return [Array<OrderDrop>] array of order objects containing orders placed by the user given
  #   as the first parameter for the transactable given as the second parameter
  # @param user [UserDrop] transactable object
  # @param transactable [TransactableDrop] transactable object
  def get_enquirer_orders(user, transactable)
    get_enquirer_draft_orders(user, transactable).active
  end

  # @return [Array<OrderDrop>] array of confirmed order objects containing orders placed by the
  # user given as the first parameter for the transactable given as the second parameter
  # @param user [UserDrop] transactable object
  # @param transactable [TransactableDrop] transactable object
  def get_enquirer_confirmed_orders(user, transactable)
    get_enquirer_draft_orders(user, transactable).confirmed
  end

  # @return [Array<OrderDrop>] array of order objects
  # @param user [UserDrop] orders returned are for items belonging to this user's companies
  # @param transactable [TransactableDrop] orders returned are for this transactable
  def get_lister_orders(user, transactable)
    transactable.line_item_orders.where(company: user.companies).active.order('created_at ASC')
  end

  # @return [Array<DataSourceContentDrop>] paginated array of DataSourceContent objects where the external_id
  #   matches the one given as the parameter; the pagination is done using options passed in
  #   as the second parameter
  # @param external_id [Integer] we will search for DataSourceContent object matching this external_id
  # @param options [Hash] options for paginating the results; only per_page will be employed
  #   e.g. 12 | get_data_contents: per_page: 5
  def get_data_contents(external_id, options = {})
    data_source_contents = DataSourceContent.where('external_id like ?', external_id)
    data_source_contents.paginate(per_page: options[:per_page].presence || 10)
  end

  # @return [Boolean] whether the element identified by the given key is visible according to the
  #   rules defined by the hidden UI controls in the admin section of the marketplace
  # @param key [String] key identifying a UI element e.g. 'dashboard/credit_cards'
  def is_visible(key)
    HiddenUiControls.find(key).visible?
  end

  # @return [Boolean] whether the given string matches the given regular expression
  # @param string [String] string we check against the regular expression
  # @param regexp [String] string representing a regular expression pattern against which
  #   we try to match the first parameter
  def matches(string, regexp)
    return false if regexp.blank?
    !!(string =~ Regexp.new(regexp))
  end

  # @return [Integer] the ID of the PaymentGateway for which the credit card payment
  #   method exists
  def get_payment_gateway_id(_str)
    PaymentGateway.with_credit_card.mode_scope.first.try(:id)
  end

  # @return [Array<Object>] array of objects obtained from the original array of objects
  #   (passed in as the object parameter) by calling the method 'method' on each object
  #   in the original array
  # @param object [Array<Object>] array of objects to be processed
  # @param method [String] method name to be called on each of the objects in the passed
  #   in array of objects
  def map(object, method)
    object.map do |o|
      if o.is_a?(Hash)
        o[method]
      else
        o.public_send(method)
      end
    end
  end

  # @return [Array<Object>] that exists in both arrays
  # @param array [Array<Object>] array of objects to be processed
  # @param other_array [Array<Object>] array of objects to be processed
  def intersection(array, other_array)
    array & other_array
  end

  # @return [Array<Object>] with objects
  # @param objects [Array<Array>] array of arrays to be processed
  def flatten(array)
    array.flatten
  end

  # @return [Object] with first object from collection that matches provided conditions
  # @param objects [Array<Object>] array of objects to be processed
  # @param conditions [Hash] hash with conditions { field_name: value }
  def detect(objects, conditions = {})
    objects.detect do |object|
      return object if conditions.to_a.all? do |attrib, val|
        object[attrib] == val
      end
    end
  end

  # @return [Array<Object>] with objects from collection that matches provided conditions
  # @param objects [Array<Object>] array of objects to be processed
  # @param conditions [Hash] hash with conditions { field_name: value }
  def select(objects, conditions = {})
    objects.select do |object|
      conditions.to_a.all? do |attrib, val|
        object[attrib] == val
      end
    end
  end

  # @return [String] formatted representation of the date object; the formatted representation
  #   will be based on what the format parameter specifies
  # @param date [Date, Time, DateTime] date object
  # @param format [String] string representing the desired output format
  # @param zone [String] string representing the time zone
  #   e.g. '%Y-%m-%d' will result in something like '2020-12-12'
  def strftime(date, format, zone = nil)
    date&.in_time_zone(zone || Time.zone.name)&.strftime(format)
  end

  # @return [MoneyDrop] a Money object constructed with the given amount and currency
  # @param amount [Float] currency amount
  # @param currency [String] name of the currency
  def to_money(amount, currency)
    Money.new(amount, currency)
  end

  # @return [String] formatted HTML snippet containing the translated time (using the 'short' format)
  #   e.g. <abbr class='timeago' title='2020-11-26T03:36:07+12:00'>3:35</abbr>
  # @param time [Time] time object
  def timeago(time)
    "<time class='timeago' datetime='#{time.to_time.iso8601}'>#{l(time, 'short')}</time>".html_safe
  end

  # @return [Array<CkeditorAssetDrop>] seller attachments tied to the given transactable object
  #   and that are visible by the given user
  # @param transactable_drop [TransactableDrop] transactable object
  # @param user_drop [UserDrop] user object
  def attachments_visible_for(transactable_drop, user_drop)
    transactable_drop.source.attachments_visible_for(user_drop.source)
  end

  # @return [Array<CkeditorAssetDrop>] paginated array of Ckeditor::Asset objects matching the given access_level
  #   and the options in the options hash
  # @param access_level [String] can be all, purchasers, enquirers, collaborators
  # @param options [Hash] options hash
  #   * sort - sort by (created_at, name)
  #   * direction - ordering direction (asc, desc)
  #   * query - string to match against the file name or the title of the object
  #   * per_page - number of items per page
  #   * page - the page to display from the paginated array
  def get_ckeditor_assets(access_level, options = {})
    sort_option = %w(created_at name).detect { |valid_key| options['sort'] == valid_key } || 'created_at'
    sort_direction = %w(asc desc).detect { |valid_key| options['direction'] == valid_key } || 'desc'
    Ckeditor::Asset.where(access_level: access_level)
                   .where('data_file_name LIKE ? OR title LIKE ?', "%#{options['query']}%", "%#{options['query']}%")
                   .order("#{sort_option} #{sort_direction}")
                   .paginate(page: options['page'] || 1, per_page: [(options['per_page'] || 10).to_i, 50].min)
  end

  # @return [String] path used for a form for creating a new message in a thread
  # @param displayed_user_message [UserMessageDrop] the parent displayed message
  # @param user_message [UserMessageDrop]
  def user_message_create_path(displayed_user_message, user_message)
    displayed_user_message.user_message.decorate.create_path(user_message.try(:user_message))
  end

  # @return [String] processed text with markdown syntax changed to HTML
  # @param text [String] text using markdown syntax
  def markdownify(text)
    markdown = MarkdownWrapper.new(text)
    markdown.to_html
  end

  # @return [Boolean] checks if user is following events for activity stream
  # @param user [User] user we are checking against
  # @param object_id [Integer] object id we are checking for
  # @param object_type [String] class name of the object we are checking for - User, Topic, Transactable
  def is_user_following(user, object_id, object_type)
    user.source.activity_feed_subscriptions.where(followed_id: object_id, followed_type: object_type).any?
  end

  # @return [String] information about the unit pricing e.g. 'Every calendar month price'
  # @param transactable_pricing [TransactablePricingDrop] transactable pricing object
  # @param base_key [String] base translation key
  # @param units_namespace [String] namespace for the units e.g. 'reservations'
  def pricing_units_translation(transactable_pricing, base_key, units_namespace)
    transactable_pricing.source.decorate.units_translation(base_key, units_namespace)
  end

  # @return [String] returns string padded from left to length of count with symbol character
  # @param str [String] string to pad
  # @param count [Integer] minimum length of output string
  # @param symbol [String] string to pad with
  def pad_left(str, count, symbol = ' ')
    str.to_s.rjust(count, symbol)
  end

  # @return [Boolean] checks if given array contains at least one queried string/number
  # @param arr [Array] array to search through
  # @param query [String, Number] String/Number compared to each item in the given array
  def any(arr = [], query = 'true')
    Array(arr).any? { |item| item == query }
  end

  def group_rules_by_day(rules)
    grouped_hash = {}
    rules.each do |rule|
      rule.fetch('days').each do |d|
        grouped_hash[d] ||= Set.new
        grouped_hash[d] << rule
      end
    end
    grouped_hash.each do |k, v|
      grouped_hash[k] = v.sort_by { |r| [r['open_hour'], r['open_minute']] }
    end
    Hash[grouped_hash.sort]
  end
end
