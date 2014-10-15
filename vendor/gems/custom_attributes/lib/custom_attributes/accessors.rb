module CustomAttributes
  module Accessors
    extend ActiveSupport::Concern

    included do

      def set_custom_attributes(store_accessor_name)
        metaclass = class << self; self; end
        hstore_attributes = custom_attributes_names_types_hash
        metaclass.class_eval do
          store_accessor store_accessor_name, hstore_attributes.keys.reject { |k| method_defined?(k) && !k.include?('_price_cents') }
        end
        custom_attributes_names_types_hash.each do |key, type|
          case type
          when :boolean
            metaclass.class_eval do
              define_method("#{key}?") do
                send(key)
              end
            end
          when :array
            metaclass.class_eval do
              define_method("#{key}=") do |val|
                case val
                when Array
                  super(val.join(','))
                else
                  super(val)
                end
              end
            end
          end
        end
        @custom_attributes_set = true
      end

      def read_store_attribute(*args)
        if (type = custom_attributes_names_types_hash[args[1]]).present?
          custom_property_type_cast(super, type)
        else
          super
        end
      end

      def custom_property_type_cast(value, type)
        klass = ActiveRecord::ConnectionAdapters::Column

        return [] if value.nil? && type == :array
        return nil if value.nil?
        case type
        when :string, :text        then value
        when :integer              then value.to_i rescue value ? 1 : 0
        when :float                then value.to_f
        when :decimal              then klass.value_to_decimal(value)
        when :datetime, :timestamp then klass.string_to_time(value).in_time_zone
        when :time                 then klass.string_to_dummy_time(value)
        when :date                 then klass.string_to_date(value)
        when :binary               then klass.binary_to_string(value)
        when :boolean              then klass.value_to_boolean(value)
        when :array                then value.split(',').map(&:strip)
        else value
        end
      end
    end

  end
end

