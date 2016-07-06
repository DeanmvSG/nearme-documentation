class Transactable::ActionType < ActiveRecord::Base
  acts_as_paranoid
  auto_set_platform_context
  scoped_to_platform_context

  AVAILABILE_UNITS = %w(day hour night event subscription_day subscription_month is_free).freeze

  belongs_to :instance
  belongs_to :transactable, -> { with_deleted }
  belongs_to :transactable_type_action_type, class_name: '::TransactableType::ActionType'
  has_many :pricings, as: :action, inverse_of: :action

  validates :transactable_type_action_type, presence: true

  delegate :timezone, :desks_booked_on, :quantity, to: :transactable
  delegate :favourable_pricing_rate, :service_fee_guest_percent,
    :service_fee_host_percent, :available_units, :allow_custom_pricings?,
    :allow_no_action?, :allow_action_rfq?, :action_continuous_dates_booking,
    :cancellation_policy_enabled, :cancellation_policy_penalty_percentage,
    :cancellation_policy_hours_for_cancellation, :cancellation_policy_penalty_hours,
    :hours_to_expiration, :hide_location_availability?, to: :transactable_type_action_type, allow_nil: true

  accepts_nested_attributes_for :pricings, allow_destroy: true, reject_if: :check_price_attributes

  scope :enabled, -> { where(enabled: true) }

  def booking_module_options
    {
      possible_units: pricings.map(&:unit).uniq,
      action_rfq: action_rfq,
      no_action: no_action,
      favourable_pricing_rate: transactable_type_action_type.favourable_pricing_rate,
    }
  end

  def available_prices
    pricings.map(&:price_information)
  end

  def available_prices_in_cents
    pricings.map(&:price_cents_information)
  end

  def pricings_for_types(price_types = [])
    pricings.select{ |p| price_types.blank? || price_types.include?(p.units_to_s) }
  end

  def has_price?
    pricings.any?{ |p| p.price_cents.to_i > 0 || p.exclusive_price_available? }
  end

  def bookable?
    true
  end

  def pricing_for(units)
    pricings.find{|p| p.units_to_s == units }
  end

  def price_for(units)
    pricing_for(units).try(:price)
  end

  def price_cents_for(units)
    pricing_for(units).try(:price_cents)
  end

  AVAILABILE_UNITS.each do |u|
    define_method("#{u}_booking?"){ pricings.any?(&:"#{u}_booking?") }
  end

  AVAILABILE_UNITS.each do |u|
    define_method("#{u}_pricings"){ pricings.select(&:"#{u}_booking?") }
  end

  def validate_all_dates_available(order)
    invalid_dates = order.periods.reject(&:bookable?)
    if invalid_dates.any?
      order.errors.add(:base, I18n.t('reservations_review.errors.dates_not_available', dates: invalid_dates.map(&:as_formatted_string).join(', ')))
    end
  end

  def open_now?
    now = Time.now.in_time_zone(timezone)
    date = now.to_date
    start_min = now.hour * 60 + now.min
    open_on?(now.to_date, start_min, start_min)
  end

  def name
    self.class.name.demodulize.underscore
  end

  def is_no_action?
    false
  end

  protected

  def check_price_attributes(attribs)
    !enabled? || attribs[:enabled] != '1' ||  attribs[:exclusive_price].to_i == 0 && attribs[:price].to_i == 0 && !attribs[:is_free_booking]
  end

end