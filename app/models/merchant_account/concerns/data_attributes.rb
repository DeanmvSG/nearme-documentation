module MerchantAccount::Concerns::DataAttributes
  extend ActiveSupport::Concern

  included do
    serialize :data, Hash

    self::ATTRIBUTES.each do |attr|
      define_method attr do
        data[attr]
      end

      define_method "#{attr}=" do |val|
        attribute_will_change!(attr)
        self.data[attr] = val
      end
    end
  end

end
