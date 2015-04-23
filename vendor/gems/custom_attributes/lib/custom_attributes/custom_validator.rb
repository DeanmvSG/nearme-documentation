module CustomAttributes
  class CustomValidator

    def initialize(store_accessor_name)
      @store_accessor_name = store_accessor_name
    end

    def validate(record)
      return true if record.skip_custom_attribute_validation
      record.custom_attributes.each do |array|
        name = array[CustomAttribute::NAME]
        type = array[CustomAttribute::ATTRIBUTE_TYPE]
        validation_rules = array[CustomAttribute::VALIDATION_RULES]
        valid_values = array[CustomAttribute::VALID_VALUES]

        if validation_rules.present? && !validation_rules.empty?
          validation_rules.each do |validation_rule_type, validation_rule_options|
            validation_rule_options ||= {}
            options = ({ attributes:  name }.merge(validation_rule_options)).symbolize_keys

            klass = case validation_rule_type.to_sym
                    when :presence
                      ActiveModel::Validations::PresenceValidator
                    when :inclusion
                      ActiveModel::Validations::InclusionValidator
                    when :numericality
                      ActiveModel::Validations::NumericalityValidator
                    when :length
                      ActiveModel::Validations::LengthValidator
                    else
                      raise "Unknown validation type: #{validation_rule_type}"
                    end
            klass.new(options).validate(record.send(:"#{@store_accessor_name}"))
          end
        end
        if valid_values.present? && type.to_sym != :array && record.send(:"#{@store_accessor_name}").send(name).present?
          unless valid_values.map { |s| s.mb_chars.downcase }.include?(record.send(:"#{@store_accessor_name}").send(name).try(:mb_chars).try(:downcase))
            record.send(:"#{@store_accessor_name}").errors.add(name, :inclusion, value: record.send(:"#{@store_accessor_name}").send(name))
          end
        end
      end
    end

  end

end
