module TransactablesIndex
  extend ActiveSupport::Concern
  
  included do |base|
    cattr_accessor :custom_attributes

    settings(index: { number_of_shards: 1 }) do
      mapping do
        indexes :custom_attributes, type: 'object' do
          if Rails.env.staging? || Rails.env.production?
            mapped = TransactableType.all.map{ |service_type|
              service_type.custom_attributes.map(&:name)
            }.flatten.uniq
            for custom_attribute in mapped
              indexes custom_attribute, type: 'string'
            end
          end
        end

        indexes :name, type: 'string'
        indexes :description, type: 'string'

        indexes :object_properties, type: 'object'
        indexes :instance_id, :type => 'integer'
        indexes :company_id, :type => 'integer'
        indexes :location_id, :type => 'integer'
        indexes :transactable_type_id, :type => 'integer'
        indexes :administrator_id, :type => 'integer'

        indexes :categories, type: 'integer'

        indexes :enabled, :type => 'boolean'
        indexes :action_rfq, :type => 'boolean'
        indexes :action_hourly_booking, :type => 'boolean'
        indexes :action_free_booking, :type => 'boolean'
        indexes :action_recurring_booking, :type => 'boolean'
        indexes :action_daily_booking, :type => 'boolean'

        indexes :hourly_price_cents, :type => 'integer'
        indexes :daily_price_cents, :type => 'integer'
        indexes :weekly_price_cents, :type => 'integer'
        indexes :monthly_price_cents, :type => 'integer'

        indexes :location_type_id, type: 'integer'

        indexes :geo_location, type: 'geo_point'

        indexes :draft, type: 'date'
        indexes :created_at, type: 'date'
      end
    end

    def as_indexed_json(options={})
      custom_attrs = {}
      
      @@custom_attributes ||= TransactableType.all.map do |service_type|
        service_type.custom_attributes.map(&:name)
      end.flatten.uniq

      for custom_attribute in @@custom_attributes
        if self.properties.respond_to?(custom_attribute)
          custom_attrs[custom_attribute] = self.properties.send(custom_attribute).to_s.downcase
        end
      end

      allowed_keys = Transactable.mappings.to_hash[:transactable][:properties].keys.delete_if { |prop| prop == :custom_attributes }

      self.as_json(only: allowed_keys).merge(
        geo_location: self.geo_location,
        custom_attributes: custom_attrs,
        location_type_id: self.location.location_type_id,
        hourly_price_cents: self.hourly_price_cents.to_i,
        daily_price_cents: self.daily_price_cents.to_i,
        weekly_price_cents: self.weekly_price_cents.to_i,
        monthly_price_cents: self.monthly_price_cents.to_i,
        categories: self.categories.pluck(:id)
      )
    end

    def self.esearch(query)
      __elasticsearch__.search(query)
    end

    def self.regular_search(query)
      query_builder = Elastic::QueryBuilder.new(query.with_indifferent_access, searchable_custom_attributes)

      __elasticsearch__.search(query_builder.geo_regular_query)
    end

    def self.searchable_custom_attributes
      TransactableType.where(searchable: true).map{ |product_type|
        product_type.custom_attributes.where(searchable: true).map(&:name)
      }.flatten.uniq.map{|m| "custom_attributes.#{m}"}
    end

    def self.geo_search(query)
      query_builder = Elastic::QueryBuilder.new(query.with_indifferent_access, searchable_custom_attributes)
      __elasticsearch__.search(query_builder.geo_query)
    end

    def object_properties
      self.properties.instance_eval{@hash}.to_json
    end

    def geo_location
      {lat: self.location.latitude, lon: self.location.longitude} if self.location
    end
  end
end