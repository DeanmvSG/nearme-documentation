# Based on: https://gist.github.com/1009861
class FileMimeTypeValidator < ActiveModel::EachValidator
  MESSAGES  = { content_type: :wrong_content_type }.freeze
  CHECKS    = [:content_type].freeze

  DEFAULT_TOKENIZER = ->(value) { value.split(//) }
  RESERVED_OPTIONS  = [:content_type, :tokenizer]

  def initialize(options)
    super
  end

  def check_validity!
    keys = CHECKS & options.keys

    if keys.empty?
      fail ArgumentError, 'Patterns unspecified. Specify the :content_type option.'
    end

    keys.each do |key|
      value = options[key]

      unless valid_content_type_option?(value)
        fail ArgumentError, ":#{key} must be a String or a Regexp or an Array"
      end

      if key.is_a?(Array) && key == :content_type
        options[key].each do |val|
          fail ArgumentError, "#{val} must be a String or a Regexp" unless val.is_a?(String) || val.is_a?(Regexp)
        end
      end
    end
  end

  def validate_each(record, attribute, value)
    fail(ArgumentError, 'A CarrierWave::Uploader::Base object was expected') unless value.is_a? CarrierWave::Uploader::Base
    value = (options[:tokenizer] || DEFAULT_TOKENIZER).call(value) if value.is_a?(String)
    return if value.length == 0

    CHECKS.each do |key|
      next unless check_value = options[key]

      if key == :content_type
        if check_value.is_a?(String) || check_value.is_a?(Regexp)
          do_validation(value, check_value, key, record, attribute)
        else
          check_value.each do |pattern|
            do_validation(value, pattern, key, record, attribute)
          end
        end
      end
    end
  end

  def help
    Helper.instance
  end

  class Helper
    include Singleton
    include ActionView::Helpers::NumberHelper
  end

  private

  def valid_content_type_option?(content_type)
    return true if %w(Array String Regexp).include?(content_type.class.to_s)
    false
  end

  def do_validation(value, pattern, key, record, attribute)
    return if value.file.content_type.send((pattern.is_a?(String) ? '==' : '=~'), pattern)

    errors_options = options.except(*RESERVED_OPTIONS)

    default_message = options[MESSAGES[key]]
    errors_options[:message] ||= default_message if default_message

    record.errors.add(attribute, MESSAGES[key], errors_options)
  end
end
