class CustomValidator < ActiveRecord::Base
  acts_as_paranoid
  auto_set_platform_context
  scoped_to_platform_context

  belongs_to :validatable, polymorphic: true
  belongs_to :instance

  serialize :valid_values, Array
  serialize :validation_rules, JSON

  validates :field_name, presence: true

  before_validation :set_validation_rules

  attr_accessor :required, :min_length, :max_length

  inherits_columns_from_association([:instance_id], :validatable)

  def inclusion?
    validation_rules.keys.include?('inclusion') || valid_values.present?
  end

  %w(presence numericality).each do |type|
    define_method("#{type}?") do
      validation_rules.keys.include?(type)
    end
  end

  def set_accessors
    self.required   = validation_rules['presence'] == {} rescue false
    self.min_length = validation_rules['length']['minimum'] rescue nil
    self.max_length = validation_rules['length']['maximum'] rescue nil
  end

  def valid_values=(values)
    if values.is_a? String
      self[:valid_values] = values.split(',')
    else
      super
    end
  end

  def set_validation_rules
    self.validation_rules ||= {}
    self.required.to_i == 1 ? (self.validation_rules['presence'] = {}) : self.validation_rules.delete('presence')
    if self.min_length.present? || self.max_length.present?
      self.validation_rules['length'] = {}
      self.min_length.present? ? self.validation_rules['length']['minimum'] = self.min_length.to_i : self.validation_rules['length'].delete('minimum')
      self.max_length.present? ? self.validation_rules['length']['maximum'] = self.max_length.to_i : self.validation_rules['length'].delete('maximum')
    else
      self.validation_rules.delete('length')
    end
  end
end