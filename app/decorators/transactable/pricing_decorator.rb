class Transactable::PricingDecorator < Draper::Decorator
  include CurrencyHelper

  delegate_all

  def units_translation(base_key, units_namespace = 'reservations')
    if units_to_s == '0_free'
      I18n.t("search.pricing_types.free")
    else
      I18n.t(
        base_key,
        no_of_units: number_of_units,
        unit: I18n.t("#{units_namespace}.#{unit}", count: number_of_units),
        count: number_of_units
      )
    end
  end

  def price_with_currency(price_name_or_object)
    actual_price = nil
    if price_name_or_object.respond_to?(:fractional)
      actual_price = price_name_or_object
    else
      actual_price = self.send(price_name_or_object)
    end

    render_money(Money.new(actual_price.try(:fractional), currency.blank? ? PlatformContext.current.instance.default_currency : currency))
  end

end
