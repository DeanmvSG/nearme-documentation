class Listing
  class SearchFetcher

    TOP_CITIES = ['san francisco', 'london', 'new york', 'los angeles', 'chicago']

    def initialize(search_scope, filters = {})
      @search_scope = search_scope
      @midpoint = filters.fetch(:midpoint)
      @radius = filters.fetch(:radius)
      @filters = filters
    end

    def listings
      filtered_listings = []
      filtered_locations.includes(:listings).each do |location|
        @listings = location.listings.searchable
        @listings = @listings.filtered_by_listing_types_ids(@filters[:listing_types_ids]) if @filters[:listing_types_ids]
        @listings.each do |listing|
          listing.distance_from_search_query = location.distance if location.respond_to?(:distance)
          filtered_listings << listing
        end
      end

      # Order in top cities
      if !@filters[:query].blank? && TOP_CITIES.any?{|city| @filters[:query].downcase.include?(city)}
        filtered_listings = filtered_listings.sort_by(&:rank).reverse
      end

      filtered_listings
    end

    private 
    def filtered_locations
      @search_scope = @search_scope.near(@midpoint, @radius, :order => :distance) if @midpoint && @radius
      @search_scope = @search_scope.filtered_by_location_types_ids(@filters[:location_types_ids]) if @filters[:location_types_ids]
      @search_scope = @search_scope.filtered_by_industries_ids(@filters[:industries_ids]) if @filters[:industries_ids]
      @search_scope
    end

    def reject_unavailable_listings
      return if @filters[:available_dates].blank?
      @filters[:available_dates].each do |date|
        @listings.reject! { |listing| listing.fully_booked_on?(date) }
      end 
    end 

  end
end
