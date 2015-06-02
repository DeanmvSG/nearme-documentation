module ProductsIndex
  extend ActiveSupport::Concern

  included do |base|
    cattr_accessor :custom_attributes

    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mapping dynamic: 'false' do
      	indexes :custom_attributes, type: 'object' do
          if Rails.env.staging? or Rails.env.production?
            mapped = Spree::ProductType.all.map{ |product_type|
              product_type.custom_attributes.map(&:name)
            }.flatten.uniq
            for custom_attribute in mapped
              indexes custom_attribute, type: 'string'
            end
          end
        end

        indexes :categories, type: 'integer'

        indexes :object_properties, type: 'object'

        indexes :name, :type => 'string'
        indexes :description, :type => 'string'

        indexes :instance_id, :type => 'integer'
        indexes :user_id, :type => 'integer'
        indexes :product_type_id, :type => 'integer'

        indexes :approved, :type => 'boolean'
        indexes :action_rfq, :type => 'boolean'

        indexes :available_on, type: 'date'
        indexes :created_at, type: 'date'

        indexes :geo_location, type: 'geo_point'
      end
    end

    def as_indexed_json(options={})
      custom_attrs = {}
      @@custom_attributes ||= Spree::ProductType.all.map{ |product_type|
        product_type.custom_attributes.map(&:name)
      }.flatten.uniq
      for custom_attribute in @@custom_attributes
        if self.respond_to?(custom_attribute)
          custom_attrs[custom_attribute] = self.send(custom_attribute).to_s
        end
      end
      self.as_json(only: Spree::Product.mappings.to_hash[:product][:properties].keys.delete_if{|prop| prop == :custom_attributes}).
        merge(geo_location: self.geo_location).
        merge(custom_attributes: custom_attrs).
        merge(categories: self.categories.map(&:id))
    end

    def self.custom_attributes_names
      @@custom_attributes ||= Spree::ProductType.all.map{ |product_type|
        product_type.custom_attributes.map(&:name)
      }.flatten.uniq
    end

    def self.searchable_custom_attributes
      Spree::ProductType.where(searchable: true).map{ |product_type|
        product_type.custom_attributes.where(searchable: true).map(&:name)
      }.flatten.uniq.map{|m| "custom_attributes.#{m}^3"}
    end

    def self.search(query)
      query_builder = Elastic::QueryBuilder.new(query.with_indifferent_access, searchable_custom_attributes)
      __elasticsearch__.search(query_builder.product_query)
    end

    def geo_location
      {lat: self.location.latitude, lon: self.location.longitude} if self.respond_to?(:location) and self.location
    end

    def object_properties
      self.extra_properties.instance_eval{@hash}.to_json
    end
  end
end