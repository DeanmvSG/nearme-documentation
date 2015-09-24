require 'forwardable'

module CustomAttributes
  class CollectionProxy
    include ActiveModel::Validations
    include Enumerable

    delegate :each, to: :@hash

    def initialize(model, store_accessor_name)
      @model = model
      metaclass = class << self; self; end

      metaclass.class_eval do
        model.custom_attributes.each do |custom_attributes_array|
          key = custom_attributes_array[CustomAttribute::NAME]
          type = custom_attributes_array[CustomAttribute::ATTRIBUTE_TYPE].to_sym

          define_method(key) { custom_property_type_cast(@hash[key], "#{type}".to_sym) }
          define_method("#{key}?") { self.send("#{key}") } if type == :boolean
          if type == :array
            define_method("#{key}=") do |val|
              @model.send("#{store_accessor_name}_will_change!")
              if val.kind_of?(Array)
                @hash[key] = val.join(',')
              else
                @hash[key] = val
              end
            end
          else
            define_method("#{key}=") do |val|
              @model.send("#{store_accessor_name}_will_change!")
              @hash[key] = val
            end
          end
        end
      end
    end

    def update_hash(hash)
      @hash = hash
    end

    def [](key)
      self.send(key)
    end

    def []=(key, value)
      send("#{key}=", value)
    end

    def to_liquid
      @hash
    end

    protected

    def custom_property_type_cast(value, type)
      return [] if value.nil? && type == :array
      return nil if value.nil?
      case type
      when :string, :text        then value
      when :integer              then value.to_i rescue value ? 1 : 0
      when :float                then value.to_f
      when :decimal              then ActiveRecord::Type::Decimal.new.type_cast_from_database(value)
      when :datetime, :timestamp then ActiveRecord::Type::DateTime.new.type_cast_from_database(value).try(:in_time_zone)
      when :time                 then ActiveRecord::Type::Time.new.type_cast_from_database(value)
      when :date                 then ActiveRecord::Type::Date.new.type_cast_from_database(value)
      when :binary               then ActiveRecord::Type::Binary.new.type_cast_from_database(value)
      when :boolean              then ActiveRecord::Type::Boolean.new.type_cast_from_database(value)
      when :array                then value.split(',').map(&:strip)
      else value
      end
    end
  end
end
