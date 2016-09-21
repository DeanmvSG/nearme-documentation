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
    PER_PAGE = 20
    PAGE = 1

    def initialize(query, searchable_custom_attributes = nil, transactable_type)
      @transactable_type = transactable_type
      @query = query
      @bounding_box = query[:bounding_box]
      @searchable_custom_attributes = searchable_custom_attributes
      @filters = []
      @not_filters = []
    end

    def current_instance
      @current_instance ||= PlatformContext.current.instance
    end

    def query_limit
      @query[:limit] || MAX_RESULTS
    end

    def query_per_page
      per_page = @query[:per_page].to_i
      (per_page > 0) ? per_page : PER_PAGE
    end

    def query_page
      page = @query[:page].to_pagination_number
      (page > 0) ? page : PAGE
    end

    def query_offset
      (query_page - 1) * query_per_page
    end

    def geo_regular_query
      @filters = initial_service_filters
      apply_geo_search_filters
      {
        size: query_limit,
        from: query_offset,
        fields: ["_id", "location_id"],
        sort: sorting_options,
        query: match_query,
        filter: {
          bool: {
            must: @filters,
            must_not: [
              exists: { field: "draft" }
            ]
          }
        }
      }.merge(aggregations)
    end

    def geo_query
      @filters = initial_service_filters + geo_filters
      apply_geo_search_filters
      query = {
        size: query_limit,
        from: query_offset,
        fields: ["_id", "location_id"],
        query: {
          filtered: {
            query: match_query,
          }
        },
        sort: sorting_options,
        filter: {
          bool: {
            must: @filters,
            must_not: [
              exists: { field: "draft" }
            ]
          }
        }
      }.merge(aggregations)
      query[:query][:filtered].merge(
        {
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
      ) if @not_filters.present?
      query
    end

    def initial_service_filters
      searchable_transactable_type_ids = @query[:transactable_type_id].to_i
      [
      	initial_instance_filter,
        {
          term: {
            transactable_type_id: searchable_transactable_type_ids
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

    def geo_filters
      if @bounding_box
        [
          {
            geo_bounding_box: {
              geo_location: {
                top_right: {
                  lat: @bounding_box.first.first.to_f,
                  lon: @bounding_box.first.last.to_f
                },
                bottom_left: {
                  lat: @bounding_box.last.first.to_f,
                  lon: @bounding_box.last.last.to_f
                }
              }
            }
          }
        ]
      else
        [
          {
            script: {
              script: "doc['service_radius'].empty || doc['geo_location'].distanceInMiles(#{@query[:lat]},#{@query[:lon]}) <= doc['service_radius'].value"
            }
          },
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
    end

    def sorting_options
      sorting_fields = []
      if @query[:sort].present?
        sorting_fields = @query[:sort].split(',').compact.map do |sort_option|
          if sort = sort_option.match(/([a-zA-Z\.\_\-]*)_(asc|desc)/)
            { sort[1] => { order: sort[2] } }
          end
        end.compact
      end
      if @query[:lat] && @query[:lon] && (sorting_fields.empty? || sorting_fields.any?{|opt| opt['distance']} )
        order = sorting_fields.find{|opt| opt['distance']}.try(:[],'distance').try(:[], :order)
        sorting_fields << {
          _geo_distance: {
            geo_location: {
              lat: @query[:lat],
              lon: @query[:lon]
            },
            order:         order || GEO_ORDER,
            unit:          GEO_UNIT,
            distance_type: GEO_DISTANCE
          }
        }
      elsif sorting_fields.empty?
        return ['_score']
      end
      sorting_fields.reject{ |opt| opt['distance'] }
    end

    def aggregations
      {
        aggs: {
          filtered_aggregations: {
            filter: {
              bool: {
                must: @filters
              }
            },
            aggs: {
              distinct_locations: {
                cardinality: {
                  field: 'location_id'
                }
              },
              maximum_price: {
                max: {
                  field: "all_prices"
                }
              },
              minimum_price: {
                min: {
                  field: "all_prices"
                }
              }
            }
          }
        }
      }
    end

    def match_query
      if @query[:query].blank?
        { match_all: { boost: QUERY_BOOST } }
      else
        query = @query[:query]
        { simple_query_string: build_multi_match(query, @searchable_custom_attributes + ['name^2', 'tags', 'description']) }
      end
    end

    def build_multi_match(query_string, custom_attributes)
      multi_match = {
        query: query_string,
        fields: custom_attributes,
        default_operator: @query[:logic_operator].presence || "OR",
        analyzer: :snowball
      }

      # You should enable fuzzy search manually. Not included in the current release
      if ENABLE_FUZZY
        multi_match.merge!({
          fuzziness: FUZZYNESS,
          analyzer: ANALYZER
        })
      end

      multi_match
    end

    def apply_geo_search_filters

      if @transactable_type.show_price_slider && @query[:price] && (@query[:price][:min].present? || @query[:price][:max].present?)
        price_min = @query[:price][:min].to_f * 100
        price_max = @query[:price][:max].to_f * 100
        price_filters = {
          range: {
            all_prices: {}
          }
        }
        price_filters[:range][:all_prices][:gt] = price_min if @query[:price][:min].to_f > 0
        price_filters[:range][:all_prices][:lte] = price_max if @query[:price][:max].to_f > 0

        @filters << price_filters
      end

      if @query[:location_types_ids] && @query[:location_types_ids].any?
        @filters << {
          terms: {
            location_type_id: @query[:location_types_ids]
          }
        }
      end

      @filters << {
        term: {
          enabled: true
        }
      }

      if current_instance.require_payout_information && !current_instance.test_mode?
        @filters << {
          term: {
            possible_payout: true
          }
        }
      end

      if @query[:date].present?
        begin
          date = Date.parse(@query[:date])
          day = date.wday + 1
          from_hour = day * 100 + (@query[:time_from].presence || '0:00').split(':').first.to_i
          to_hour = day * 100 + (@query[:time_to].presence || '23:00').split(':').first.to_i

          @filters << {
            range: {
              open_hours: {
                gte: from_hour,
                lte: to_hour
              }
            }
          }

          @filters << {
            not: {
              term: { availability_exceptions: date }
            }
          }
        rescue ArgumentError
          # wrong date
        end
      end

      if @query[:date].blank? && @query[:time_from].present? || @query[:time_to].present?
        from_hour = (@query[:time_from].presence || '0:00').split(':').first.to_i
        to_hour = (@query[:time_to].presence || '23:00').split(':').first.to_i

        @filters << {
          range: {
            open_hours_during_week: {
              gte: from_hour,
              lte: to_hour
            }
          }
        }
      end

      if @query[:lg_custom_attributes]
        @query[:lg_custom_attributes].each do |key, value|
          value.reject! { |c| c.empty? } if value.instance_of?(Array)

          unless value.blank?
            @filters << {
              terms: {
                "custom_attributes.#{key}" =>  if value.instance_of?(Array)
                  value
                else
                  value.to_s.split(',')
                end.map{ |val| val.downcase }
              }
            }
          end
        end
      end

      category_search_type = @transactable_type.category_search_type

      if @query[:category_ids] && @query[:category_ids].any?
        if category_search_type == 'OR'
          @filters << {
            terms: {
              categories: @query[:category_ids].map(&:to_i)
            }
          }
        elsif category_search_type == 'AND'
          @query[:category_ids].each do |category|
            @filters << {
              terms: {
                categories: [category.to_i]
              }
            }
          end
        end
      end

      if @query[:listing_pricing] && @query[:listing_pricing].any?
        @filters << {
          terms: {
            all_price_types: @query[:listing_pricing]
          }
        }
      end

      if @query[:date_range].any?
        date_range = {
          or: [
            {
              range: {
                availability: {
                  gte: @query[:date_range].first,
                  lte: @query[:date_range].last
                }
              }
            }
          ]
        }
        if @transactable_type.date_pickers_relative_mode?
          date_range[:or] << {
            terms: {
              opened_on_days: @query[:date_range].map(&:wday).uniq
            }
          }
        else
          date_range[:or] << { bool: {} }
          date_range[:or].last[:bool][:must] = @query[:date_range].map(&:wday).uniq.map  do |day|
            {
              term: {
                opened_on_days: day
              }
            }
          end
        end
        @filters << date_range
      end
    end
  end
end
