class Listing
  module Search

    class SearchTypeNotSupported < StandardError; end

    extend ActiveSupport::Concern

    included do
      # thinking sphinx index
      define_index do
        join location

        indexes :name, :description

        has "radians(#{Location.table_name}.latitude)",  as: :latitude,  type: :float
        has "radians(#{Location.table_name}.longitude)", as: :longitude, type: :float

        group_by :latitude, :longitude
      end
    end

    module ClassMethods

      def find_by_search_params(params)
        listings = if params.has_key?(:boundingbox)
          find_by_boundingbox(params.delete(:boundingbox))
        elsif params.has_key?(:query)
          find_by_keyword(params.delete(:query))
        else
          raise SearchTypeNotSupported.new("You must specify either a bounding box or keywords to search by")
        end

        # now score listings
        Scorer.score(listings, params)

        # return scored listings
        listings
      end

      private

        # we use Sphinx's geosearch here, which takes a midpoint and radius
        def find_by_boundingbox(boundingbox)
          north_west = [boundingbox[:start][:lat], boundingbox[:start][:lon]]
          south_east = [boundingbox[:end][:lat],   boundingbox[:end][:lon]]

          midpoint         = Geocoder::Calculations.geographic_center([north_west, south_east])
          radius           = Geocoder::Calculations.distance_between(north_west, midpoint, units: :m)

          # sphinx needs the coordinates in radians
          midpoint_radians = Geocoder::Calculations.to_radians(midpoint)

          search(
            geo:  midpoint_radians,
            with: { "@geodist" => radius }
          )
        end

        def find_by_keyword(query)
          # sphinx :)
          search(query)
        end

    end
  end
end