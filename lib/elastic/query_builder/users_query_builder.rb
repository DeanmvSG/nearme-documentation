module Elastic
  class QueryBuilder::UsersQueryBuilder < QueryBuilder
    def initialize(query, instance_profile_type:, searchable_custom_attributes: [], query_searchable_attributes: [])
      @query = query

      @searchable_custom_attributes = searchable_custom_attributes
      @query_searchable_attributes = query_searchable_attributes
      @instance_profile_type = instance_profile_type

      @filters = []
      @not_filters = []
    end

    def regular_query
      @filters = profiles_filters

      {
        size: query_limit,
        from: query_offset,
        fields: ['_id'],
        sort: sorting_options,
        query: match_query,
        filter: {
          bool: {
            must: @filters
          }
        }
      }.merge(aggregations)
    end

    def match_query
      if @query[:query].blank?
        { match_all: { boost: QUERY_BOOST } }
      else
        {
          bool: {
            should: [
              {
                simple_query_string: {
                  query: @query[:query],
                  fields: search_by_query_attributes
                }
              },
              {
                nested: {
                  path: 'user_profiles',
                  query: {
                    multi_match: {
                      query: @query[:query],
                      fields: @query_searchable_attributes
                    }
                  }
                }
              }
            ]
          }
        }
      end
    end

    def search_by_query_attributes
      searchable_main_attributes + @query_searchable_attributes
    end

    def searchable_main_attributes
      ['name^2', 'tags^10', 'company_name']
    end

    def sorting_options
      sorting_fields = []

      if @query[:sort].present?
        sorting_fields = @query[:sort].split(',').compact.map do |sort_option|
          next unless sort = sort_option.match(/([a-zA-Z\.\_\-]*)_(asc|desc)/)
          sort_column = "user_profiles.properties.#{sort[1].split('.').last}.raw"
          {
            sort_column => {
              order: sort[2],
              nested_filter: {
                term: {
                  'user_profiles.instance_profile_type_id': @instance_profile_type.id
                }
              }
            }
          }
        end.compact
      end

      return ['_score'] if sorting_fields.empty?

      sorting_fields
    end

    def aggregations
      {}
    end

    def profiles_filters
      user_profiles_filters = [
        {
          match: {
            'user_profiles.enabled': true
          }
        },
        {
          match: {
            'user_profiles.instance_profile_type_id': @instance_profile_type.id
          }
        }
      ]

      if @query[:category_ids].present?
        category_ids = @query[:category_ids].split(',')
        if @instance_profile_type.category_search_type == 'OR'
          user_profiles_filters << {
            terms: {
              'user_profiles.category_ids': category_ids.map(&:to_i)
            }
          }
        elsif @instance_profile_type.category_search_type == 'AND'
          category_ids.each do |category|
            user_profiles_filters << {
              terms: {
                'user_profiles.category_ids': [category.to_i]
              }
            }
          end
        end
     end

      if @query[:lg_custom_attributes]
        @query[:lg_custom_attributes].each do |key, value|
          next if value.blank?
          user_profiles_filters <<
            {
              match: {
                "user_profiles.properties.#{key}.raw" => value.to_s.split(',').map(&:downcase).join(' OR ')
              }
            }
        end
      end

      if @instance_profile_type.search_only_enabled_profiles?
        initial_instance_filter + [
          {
            nested: {
              path: 'user_profiles',
              query: {
                bool: {
                  must: user_profiles_filters
                }
              }
            }
          }
        ]
      else
        initial_instance_filter << {
          term: {
            instance_profile_type_ids: @instance_profile_type.id
          }
        }
      end
    end

    def initial_instance_filter
      [
        {
          term: {
            instance_id: @query[:instance_id]
          }
        }
      ]
    end
  end
end
