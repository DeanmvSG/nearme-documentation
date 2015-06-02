module Elastic
  class QueryBuilder

    QUERY_BOOST = 1.0
    ENABLE_FUZZY = false
    ENABLE_PARTIAL = false
    FUZZYNESS = 2
    ANALYZER = 'snowball'
    GEO_DISTANCE = 'plane'
    GEO_UNIT = 'km'
    GEO_ORDER = 'asc'
    MAX_RESULTS = 1000

    def initialize(query, searchable_custom_attributes)
      @query = query
      @searchable_custom_attributes = searchable_custom_attributes
      @filters = []
      @not_filters = []
    end

    def query_limit
      @query[:limit] || MAX_RESULTS
    end

    def product_query
      @filters = initial_product_filters
      apply_product_search_filters
      {
        size: query_limit,
        sort: ['_score'],
        query: {
          multi_match: products_match_query
        },
        filter: {
          bool: {
            must: @filters
          }
        }
      }
    end

    def geo_regular_query
      @filters = initial_service_filters
      apply_geo_search_filters
      {
        size: query_limit,
        sort: ['_score'],
        query: match_query,
        filter: {
          bool: {
            must: @filters
          }
        }
      }
    end

    def geo_query
      @filters = initial_service_filters + geo_filters
      apply_geo_search_filters
      {
        size: query_limit,
        query: {
          filtered: {
            query: match_query,
            filter: {
              not: {
                filter: {
                  bool:{
                    must: @not_filters
                  }
                }
              }
            }
          }
        },
        sort: geo_sort,
        filter: {
          bool: {
            must: @filters
          }
        }
      }
    end

    def initial_service_filters
      searchable_service_type_ids = [@query[:transactable_type_id].to_i] & TransactableType.where(searchable: true).map(&:id)
      searchable_service_type_ids = [0] if searchable_service_type_ids.empty?
      [
      	initial_instance_filter,
        {
          term: {
            transactable_type_id: searchable_service_type_ids
          }
        }
      ]
    end

    def initial_instance_filter
      {
        term: {
          instance_id: @query[:instance_id]
        }
      }
    end

    def initial_product_filters
      searchable_product_type_ids = Spree::ProductType.where(searchable: true).map(&:id)
      searchable_product_type_ids = [0] if searchable_product_type_ids.empty?
      [
        initial_instance_filter,
        {
          term: {
            product_type_id: searchable_product_type_ids
          }
        }
      ]
    end

    def geo_filters
      [
        {
          geo_distance: {
            distance: @query[:distance],
            geo_location: {
              lat: @query[:lat],
              lon: @query[:lon]
            }
          }
        }
      ]
    end

    def geo_sort
      [
        {
          _geo_distance: {
            geo_location: {
              lat: @query[:lat],
              lon: @query[:lon]
            },
            order:         GEO_ORDER,
            unit:          GEO_UNIT,
            distance_type: GEO_DISTANCE
          }
        }
      ]
    end

    def match_query
      if @query[:query].blank?
        { match_all: { boost: QUERY_BOOST } }
      else
        { multi_match: build_multi_match(@query[:query], @searchable_custom_attributes + ['name^2', 'description']) }
      end
    end

    def build_multi_match(query_string, custom_attributes)
      multi_match = {
        query: query_string,
        fields: custom_attributes
      }

      # You should enable fuzzy search manually. Not included in the current release
      if ENABLE_FUZZY
        multi_match.merge ({
          fuzziness: FUZZYNESS,
          analyzer: ANALYZER
        })
      end

      multi_match
    end

    def products_match_query
      build_multi_match(@query[:name], @searchable_custom_attributes + ['name^2', 'description'])
    end

    def apply_product_search_filters
      if @query[:category_ids] && @query[:category_ids].any?
        @filters << {
          terms: {
            categories: @query[:category_ids].map(&:to_i)
          }
        }
      end
    end

    def apply_geo_search_filters
      if @query[:location_types_ids] && @query[:location_types_ids].any?
        @filters << {
          terms: {
            location_type_id: @query[:location_types_ids].map(&:id)
          }
        }
      end

      if @query[:lg_custom_attributes]
        @query[:lg_custom_attributes].each do |key, value|
          unless value.blank?
            @filters << {
              terms: {
                "custom_attributes.#{key}" => value.to_s.downcase.scan(/\w+/).map(&:strip).map(&:downcase)
              }
            }
          end
        end
      end

      if @query[:listing_pricing] && @query[:listing_pricing].any?
        @query[:listing_pricing].each do |lp|
          @not_filters << {
            term: {
              "#{lp}_price_cents" => 0
            }
          }
        end
      end
    end

  end
end