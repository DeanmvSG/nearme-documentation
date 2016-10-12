module TransactablesIndex
  extend ActiveSupport::Concern

  included do |_base|
    cattr_accessor :custom_attributes

    settings(index: { number_of_shards: 1 }) do
      mapping do
        indexes :custom_attributes, type: 'object' do
          if TransactableType.table_exists?
            mapped = TransactableType.all.map do |transactable_type|
              transactable_type.custom_attributes.pluck(:name)
            end.flatten.uniq
            for custom_attribute in mapped
              indexes custom_attribute, type: 'string', index: 'not_analyzed'
            end
          end
        end

        indexes :name, type: 'string'
        indexes :description, type: 'string'

        indexes :object_properties, type: 'object'
        indexes :instance_id, type: 'integer'
        indexes :company_id, type: 'integer'
        indexes :location_id, type: 'integer'
        indexes :transactable_type_id, type: 'integer'
        indexes :administrator_id, type: 'integer'

        indexes :categories, type: 'integer'

        indexes :enabled, type: 'boolean'
        indexes :action_rfq, type: 'boolean'
        indexes :action_free_booking, type: 'boolean'

        indexes :minimum_price_cents, type: 'integer'
        indexes :maximum_price_cents, type: 'integer'
        indexes :all_prices, type: 'integer'
        indexes :all_price_types, type: 'string'

        indexes :location_type_id, type: 'integer'

        indexes :geo_location, type: 'geo_point'
        indexes :service_radius, type: 'integer'
        indexes :open_hours, type: 'integer'
        indexes :open_hours_during_week, type: 'integer'
        indexes :opened_on_days, type: 'integer'

        indexes :availability, type: 'date'
        indexes :availability_exceptions, type: 'date'
        indexes :draft, type: 'date'
        indexes :created_at, type: 'date'
        indexes :completed_reservations, type: 'integer'
        indexes :seller_average_rating, type: 'float'
        indexes :average_rating, type: 'float'
        indexes :possible_payout, type: 'boolean'
        indexes :tags, type: 'string'
        indexes :state, type: 'string'
      end
    end

    def as_indexed_json(_options = {})
      custom_attrs = {}
      custom_attribs = transactable_type.cached_custom_attributes.map { |c| c[0] }

      for custom_attribute in custom_attribs
        if properties.respond_to?(custom_attribute)
          val = properties.send(custom_attribute)
          val = Array(val).map { |v| v.to_s.downcase }
          custom_attrs[custom_attribute] = (val.size == 1 ? val.first : val)
        end
      end

      allowed_keys = Transactable.mappings.to_hash[:transactable][:properties].keys.delete_if { |prop| prop == :custom_attributes }
      availability_exceptions = self.availability_exceptions ? self.availability_exceptions.map(&:all_dates).flatten : nil
      if action_type
        price_types = action_type.pricings.map(&:units_to_s)
        price_types << '0_free' if action_type.try(:is_free_booking?)
      else
        price_types = []
      end

      as_json(only: allowed_keys).merge(
        geo_location: geo_location,
        custom_attributes: custom_attrs,
        location_type_id: location.try(:location_type_id),
        categories: categories.pluck(:id),
        availability: schedule_availability,
        availability_exceptions: availability_exceptions,
        all_prices: all_prices,
        all_price_types: price_types,
        service_radius: properties.try(:service_radius),
        open_hours: availability.try(:days_with_hours),
        open_hours_during_week: availability.try(:open_hours_during_week),
        completed_reservations: orders.reservations.reviewable.count,
        seller_average_rating: creator.try(:seller_average_rating),
        tags: tags_as_comma_string,
        state: state
      )
    end

    def self.esearch(query)
      __elasticsearch__.search(query)
    end

    def self.regular_search(query, transactable_type = nil)
      query_builder = Elastic::QueryBuilder.new(query.with_indifferent_access, searchable_custom_attributes(transactable_type), transactable_type)
      __elasticsearch__.search(query_builder.geo_regular_query)
    end

    def self.searchable_custom_attributes(transactable_type = nil)
      if transactable_type.present?
        # m[0] - name, m[7] - searchable
        transactable_type.cached_custom_attributes.map { |m| "custom_attributes.#{m[0]}" if m[7] == true }.compact.uniq
      else
        TransactableType.where(searchable: true).map do |transactable_type|
          transactable_type.custom_attributes.where(searchable: true).map { |m| "custom_attributes.#{m.name}" }
        end.flatten.uniq
      end
    end

    def self.geo_search(query, transactable_type = nil)
      query_builder = Elastic::QueryBuilder.new(query.with_indifferent_access, searchable_custom_attributes(transactable_type), transactable_type)
      __elasticsearch__.search(query_builder.geo_query)
    end

    def object_properties
      properties.instance_eval { @hash }.to_json
    end

    def geo_location
      { lat: location.latitude.to_f, lon: location.longitude.to_f } if location
    end
  end
end
