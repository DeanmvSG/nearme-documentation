class Listing::Search::Params::Web < Listing::Search::Params
  attr :location_string
  attr_reader :location_types_ids, :industries_ids, :lntype, :lgtype, :lgpricing,
    :lntypes, :sort, :dates, :start_date, :end_date, :display_dates, :lg_custom_attributes

  def initialize(options)
    super
    @location_types_ids = @options[:location_types_ids]
    @lntype = @options[:lntype].blank? ? nil : @options[:lntype]
    @lgtype = @options[:lgtype].blank? ? nil : @options[:lgtype]
    @lgpricing = @options[:lgpricing]
    @sort = (@options[:sort].presence || 'relevance').inquiry
    @dates = (@options[:availability].present? && @options[:availability][:dates][:start].present? &&
              @options[:availability][:dates][:end].present?) ? @options[:availability][:dates] : nil
    @display_dates = (@options[:start_date].present? && @options[:end_date].present?) ?
      { start: @options[:start_date], end: @options[:end_date] } : nil
    @lg_custom_attributes = @options[:lg_custom_attributes] || {}
    @lg_custom_attributes.each do |key, value|
      @lg_custom_attributes[key] = (String === value ? value.split(',') : value).map(&:strip)
    end
  end

  def bounding_box
    @bounding_box ||= [[@options[:nx], @options[:ny]], [@options[:sx], @options[:sy]]] if @options[:nx].present?
    super
  end

  def midpoint
    super
    @midpoint ||= [@options[:lat], @options[:lng]] if @options[:lat].present?
    @midpoint
  end

  def get_address_component(val, name_type = :long)
    if location.present?
      location.fetch_address_component(val, name_type)
    else
      options[val.to_sym]
    end
  end

  def street
    get_address_component("street")
  end

  def suburb
    get_address_component("suburb")
  end

  def city
    get_address_component("city")
  end

  def state
    get_address_component("state")
  end

  def state_short
    get_address_component("state", :short)
  end

  def country
    get_address_component("country")
  end

  def is_united_states?
    query.to_s.downcase.include?('united states') || country == 'United States'
  end

  def postcode
    get_address_component("postcode")
  end

  def lntypes
    return [] if @lntype.nil?
    @lntypes ||= LocationType.where('lower(name) = any(array[?])', @lntype.to_s.split(','))
  end

  def lntypes_filters
    lntypes.map(&:name).map(&:downcase)
  end

  def location_types_ids
    @location_types_ids.presence || (lntypes.empty? ? nil : lntypes)
  end

  def lgtypes
    return [] if @lgtype.nil?
    @lgtypes ||= @lgtype.to_s.split(',')
  end

  def lgtypes_filters
    lgtypes
  end

  def lgpricing_filters
    @lgpricing.to_s.split(',')
  end

  def start_date
    return nil unless @dates
    @dates[:start]
  end

  def end_date
    return nil unless @dates
    @dates[:end]
  end

  def display_dates
    return { start: nil, end: nil } unless @display_dates
    @display_dates
  end
end
