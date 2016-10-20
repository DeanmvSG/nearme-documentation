class DelayedReservation < Reservation
  attr_accessor :dates_fake, :checkout_update

  validate :dates_fake_present, if: -> { checkout_update }
  validate :start_time_present, if: -> { checkout_update }
  before_validation :update_reservation_period, if: -> { checkout_update }

  def skip_payment_authorization
    true
  end
  alias skip_payment_authorization? skip_payment_authorization

  def self.workflow_class
    Reservation
  end

  # archived_at should not be set based on ends_at for this Order
  def set_archived_at
    true
  end

  def add_line_item!(attrs)
    self.attributes = attrs
    self.reservation_type = transactable.transactable_type.reservation_type
    self.settings = reservation_type.try(:settings)
    self.owner_id = user_id
    add_line_item_without_validation_setup
    save(validate: false)
  end

  def add_line_item_without_validation_setup
    set_inheritated_data
    set_minimum_booking_minutes
    set_dates_from_search
    build_periods
    self.quantity ||= 1
    self.skip_try_to_activate = true
  end

  def before_checkout_callback
    set_dates_from_search if dates_fake.blank?
  end

  def dates_fake_present
    errors.add(:dates_fake, :blank) if dates_fake.blank?
  end

  def start_time_present
    if transactable_pricing.hour_booking?
      errors.add(:start_time, :blank) unless start_time.present? && start_time.split(':').count == 2
    end
  end

  def with_delivery?
    true
  end

  def enquirer_cancelable
    state == 'unconfirmed'
  end
  alias_method :enquirer_cancelable?, :enquirer_cancelable

  def rebuild_first_line_item
    if transactable_line_items.any?
      transactable_line_items.destroy_all
      transactable_line_items.build(
        user: user,
        name: transactable.name,
        quantity: self.quantity,
        line_item_source: transactable,
        unit_price: price_calculator.price,
        line_itemable: self,
        service_fee_guest_percent: action.service_fee_guest_percent,
        service_fee_host_percent: action.service_fee_host_percent,
        minimum_lister_service_fee_cents: action.minimum_lister_service_fee_cents,
        transactable_pricing_id: try(:transactable_pricing_id)
      )
      update_payment_attributes
    end
  end

  def update_reservation_period
    @dates = dates_fake
    return if @dates.blank?
    if transactable_pricing.hour_booking? || transactable_pricing.day_booking?
      set_start_minute
      @start_minute = start_minute.try(:to_i)
      @end_minute = end_minute.try(:to_i)
      @dates = @dates.split(',')
      @dates = @dates.take(1)
      @dates.flatten!
      @dates.reject(&:blank?).each do |date_string|
        begin
          date = DateTimeHandler.new.convert_to_date(date_string)
        rescue
          errors.add(:dates_fake, I18n.t('reservations_review.errors.invalid_date'))
          return false
        end
        if date.past? && !date.today?
          errors.add(:dates_fake, I18n.t('reservations_review.errors.invalid_date'))
        end
        if transactable_pricing.day_booking? && periods.count != transactable_pricing.number_of_units
          @dates = transactable_pricing.number_of_units.times.map do |unit|
            (date + unit.day).to_date.to_s
          end.join(',')
          periods.destroy_all
          build_periods
          rebuild_first_line_item
        else
          periods.first.update_attributes(date: date, start_minute: @start_minute, end_minute: @end_minute)
        end
      end
    end
    self.checkout_update = false
    true
  end
end
