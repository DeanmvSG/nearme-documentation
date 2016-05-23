class InstanceType::Searcher::Elastic::GeolocationSearcher::Listing
  include InstanceType::Searcher::Elastic::GeolocationSearcher

  def initialize(transactable_type, params)
    @transactable_type = transactable_type
    @params = params
    set_options_for_filters
    @filters = {date_range: search.available_dates}

    listing_ids = fetcher.map(&:id)
    listings_scope = ::Transactable.all

    if postgres_filters?
      listings_scope = available_listings(listings_scope)
      order_ids = listing_ids[@offset..(@to + 5)]
      order_ids = listing_ids if order_ids.blank?
    else
      @search_results_count = fetcher.response[:hits][:total]
      order_ids = listing_ids
    end
    listings_scope = listings_scope.where(id: listing_ids)

    @results = listings_scope.includes(:location, :location_address, :company, :photos, :service_type).
      order_by_array_of_ids(order_ids)
  end

  def filters
    search_filters = {}
    search_filters[:location_type_filter] = @params[:location_types_ids].map { |lt| LocationType.find(lt).name } if @params[:location_types_ids]
    search_filters[:custom_attributes] = @params[:lg_custom_attributes] unless @params[:lg_custom_attributes].blank?
    search_filters
  end

  def max_price
    return 0 if !@transactable_type.show_price_slider || results.blank?
    max = fetcher.response[:aggregations]["filtered_price_range"]["maximum_price"].try(:[],'value') || 0
    max / 100
  end

  private

  def initialize_search_params
    { instance_id: PlatformContext.current.instance.id, transactable_type_id: @transactable_type.id }
  end

end
