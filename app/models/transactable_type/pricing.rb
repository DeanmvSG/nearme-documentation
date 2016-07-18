class TransactableType::Pricing < ActiveRecord::Base
  MAX_PRICE = 2147483647
  acts_as_paranoid
  auto_set_platform_context
  scoped_to_platform_context

  belongs_to :instance
  belongs_to :action, polymorphic: true, inverse_of: :pricings

  delegate :default_currency, to: :action

  monetize :min_price_cents, allow_nil: true
  monetize :max_price_cents, allow_nil: true

  validates :min_price_cents, :max_price_cents,
    numericality: { greater_than_or_equal_to: 0,
      less_than_or_equal_to: MAX_PRICE }, allow_blank: true
  validates :min_price_cents,
    numericality: { less_than_or_equal_to: :max_price_for_validation }, allow_blank: true

  validates :number_of_units, numericality: { greater_than: 0 }, presence: true
  validates :unit, presence: true
  validate :check_pricing_uniqueness

  scope :ordered_by_unit, -> { order('unit DESC, number_of_units ASC') }

  def units_to_s
    [number_of_units, unit].join('_')
  end

  def units_translation(base_key, units_key = 'reservations')
    if units_to_s == '0_free'
      I18n.t("search.pricing_types.free")
    else
      I18n.t(
        base_key,
        no_of_units: number_of_units,
        unit: I18n.t("#{units_key}.#{unit}", count: number_of_units),
        count: number_of_units
      )
    end
  end

  def max_price_for_validation
    max_price_cents.to_i > 0  ? max_price_cents : MAX_PRICE
  end

  def build_transactable_pricing(action_type)
    action_type.pricings.new(
      slice(:number_of_units, :unit).merge({
        action: action_type,
        transactable_type_pricing: self,
        price: 0.to_money
      })
    )
  end

  private

  def check_pricing_uniqueness
    if action && action.pricings.select{ |p| p.units_to_s == units_to_s }.many?
      errors.add(:number_of_units, I18n.t('errors.messages.price_type_exists'))
    end
  end
end