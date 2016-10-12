class CurrencyInput < SimpleForm::Inputs::GroupedCollectionSelectInput
  COMMON_CODES = %w(USD EUR NZD AUD GBP)

  def grouped_collection
    if allowed_currencies = options[:allowed_currencies].presence
      all_currencies = currencies.select { |c| allowed_currencies.include? c[:iso_code] }.sort_by { |c| allowed_currencies.index(c) }.reverse
      common = all_currencies.select { |c| COMMON_CODES.include? c[:iso_code] }.sort_by { |c| COMMON_CODES.index(c) }.reverse

      [prep_currencies('Common', common), prep_currencies('All', all_currencies - common)]
    else
      common = currencies.select { |c| COMMON_CODES.include? c[:iso_code] }.sort_by { |c| COMMON_CODES.index(c) }.reverse
      [prep_currencies('Common', common), prep_currencies('All', currencies - common)]
    end
  end

  def group_method
    :currencies
  end

  def group_label_method
    :name
  end

  def prep_currencies(name, currencies)
    CurrencyGroup.new(name, currencies.collect do |c|
      Currency.new(c[:iso_code], c[:name])
    end)
  end

  def currencies
    @currencies ||= begin
      DesksnearMe::Application.config.supported_currencies.sort_by { |c| c[:iso_code] }
    end
  end

  class CurrencyGroup < Struct.new(:name, :currencies)
    def include?(name)
      currencies.any? { |c| c.name == name }
    end
  end

  class Currency < Struct.new(:iso_code, :aname)
    def name
      "#{iso_code} - #{aname}"
    end

    def to_s
      iso_code
    end
  end
end
