class InstanceType::Searcher::Elastic::GeolocationSearcher::Location
  include InstanceType::Searcher::Elastic::GeolocationSearcher

  def initialize(transactable_type, params)
    @transactable_type = transactable_type
    @params = params
    set_options_for_filters
    @filters = {date_range: search.available_dates}
    locations = {}

    fetcher.each{|f|
      locations[f.fields.location_id.first] ||= []
      locations[f.fields.location_id.first] << f.id
    }

    location_ids = locations.keys

    if postgres_filters?
      listings_scope = Transactable.where(id: locations.values.flatten)
      listings_scope = available_listings(listings_scope)
      listings_scope = price_filter(listings_scope)

      order_ids = locations.keys[@offset..@to]
      filtered_listings = Transactable.where(id: listings_scope.pluck(:id))
    else
      @search_results_count = locations.size
      locations = locations.to_a[@offset..@to].to_h

      order_ids = location_ids
      filtered_listings = Transactable.where(id: locations.values.flatten)
    end
    @results = ::Location.includes(:location_address, :company, listings: [:service_type, :photos]).
      where(id: location_ids).order_by_array_of_ids(order_ids).
      merge(filtered_listings)
  end

  def per_page_elastic; end

  def page_elastic; end

  def max_price
    return 0 if !PlatformContext.current.instance.price_slider || results.blank?
    @max_fixed_price ||= results.map{|r|
      r.listings.map(&:fixed_price_cents).max
    }.max / 100
    @max_fixed_price > 0 ? @max_fixed_price + 1 : @max_fixed_price
  end

  def filters
    search_filters = {}
    search_filters[:location_type_filter] = search.location_types_ids.map { |lt| lt.respond_to?(:name) ? lt.name : lt } if search.location_types_ids && !search.location_types_ids.empty?
    search_filters[:listing_pricing_filter] = search.lgpricing_filters if not search.lgpricing_filters.empty?
    search_filters[:custom_attributes] = @params[:lg_custom_attributes] unless @params[:lg_custom_attributes].blank?
    search_filters
  end

  private

  def initialize_search_params
    { instance_id: PlatformContext.current.instance.id, transactable_type_id: @transactable_type.id }
  end

end