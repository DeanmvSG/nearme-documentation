class InstanceType::Searcher::GeolocationSearcher::Listing
  include InstanceType::Searcher::GeolocationSearcher

  def initialize(transactable_type, params)
    @transactable_type = transactable_type
    set_options_for_filters
    @params = params
  end

  def invoke
    @results = fetcher.listings
  end

  def filters
    search_filters = {}
    search_filters[:location_type_filter] = @params[:location_types_ids].map { |lt| LocationType.find(lt).name } if @params[:location_types_ids]
    search_filters[:custom_attributes] = @params[:lg_custom_attributes] unless @params[:lg_custom_attributes].blank?
    search_filters
  end

  def max_price
    return 0 if !@transactable_type.show_price_slider || @results.blank?
    @max_fixed_price ||= (@results.map(&:action_type).map(&:pricings).flatten.map(&:price_cents).compact.max || 0).to_f / 100
    @max_fixed_price > 0 ? @max_fixed_price + 1 : @max_fixed_price
  end

end
