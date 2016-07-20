class Transactable::TimeBasedBooking < Transactable::ActionType
  include AvailabilityRule::TargetHelper

  belongs_to :availability_template
  has_many :availability_templates, as: :parent

  delegate :availability_for, to: :transactable

  accepts_nested_attributes_for :availability_template

  validates_numericality_of :minimum_booking_minutes, greater_than_or_equal_to: 15, allow_blank: true
  validate :booking_availability, if: :night_booking?
  validates :pricings, presence: true, if: :enabled?
  validates_associated :pricings, if: :enabled?

  # Number of minimum consecutive booking days required for this listing
  def minimum_booking_days
    (day_pricings + night_pricings).map(&:number_of_units).min
  end

  def minimum_booking_minutes
    super || transactable_type_action_type.try(:minimum_booking_minutes)
  end

  def available_prices
    pricings.map(&:price_information)
  end

  def overnight_booking?
    night_booking?
  end

  def availability_template
    super || transactable.location.try(:availability_template)
  end

  def availability_exceptions
    availability_template.try(:future_availability_exceptions)
  end

  def custom_availability_template?
    availability_template.try(:custom_for_transactable?)
  end

  def first_available_date
    time = Time.now.in_time_zone(timezone)
    date = time.to_date
    max_date = date + 60.days

    closed_at = availability.close_minute_for(date)

    if closed_at && (closed_at < (time.hour * 60 + time.min + minimum_booking_minutes))
      date = date + 1.day
    end
    date = date + 1.day until availability_for(date) > 0 || date == max_date
    date
  end

  def second_available_date
    date = first_available_date + 1.day

    max_date = date + 31.days
    date = date + 1.day until availability_for(date) > 0 || date == max_date
    date
  end

  # Returns a hash of booking block sizes to prices for that block size.
  def prices_by_days
    Hash[day_pricings.map(&:units_and_price)
      .sort{|a,b| a[1][:price] <=> b[1][:price]}]
  end

  def prices_by_nights
    Hash[night_pricings.map(&:units_and_price)
      .sort{|a,b| a[1][:price] <=> b[1][:price]}]
  end

  def prices_by_hours
    Hash[hour_pricings.map(&:units_and_price)
      .sort{|a,b| a[1][:price] <=> b[1][:price]}]
  end

  def price_for_lowest_no_of_day
    if day_booking?
      pricings.select(&:day_booking?).sort_by(&:number_of_units).first.price
    end
  end

  def prices_by_hours_cents
    Hash[hour_pricings.map(&:units_and_price_cents).sort{|a,b| a[1][:price] <=> b[1][:price]}]
  end

  def prices_by_days_cents
    Hash[day_pricings.map(&:units_and_price_cents).sort{|a,b| a[1][:price] <=> b[1][:price]}]
  end

  def prices_by_nights_cents
    Hash[night_pricings.map(&:units_and_price_cents).sort{|a,b| a[1][:price] <=> b[1][:price]}]
  end

  def open_on?(date, start_min = nil, end_min = nil)
    Time.use_zone(timezone) do
      availability.try(:open_on?, date: date.in_time_zone, start_minute: start_min, end_minute: end_min)
    end
  end

  def hourly_availability_schedule(date)
    AvailabilityRule::HourlyListingStatus.new(self, date)
  end

  def booking_module_options
    first_date = first_available_date
    second_date = second_available_date

    # Daily open/quantity availability data for datepickers
    time_now = Time.now.in_time_zone(timezone)
    minimum_date = time_now.to_date

    close_minute = availability.close_minute_for(minimum_date)
    if close_minute.present? && (close_minute < (time_now.hour * 60 + time_now.min + minimum_booking_minutes))
      minimum_date = time_now.tomorrow.to_date
    end

    availability_dates = availability_status_between(minimum_date, minimum_date.advance(:years => 1))

    hash = super.merge({
      booking_type: 'time_based',
      availability: availability_dates.as_json,
      minimum_date: availability_dates.start_date,
      maximum_date: availability_dates.end_date,
      first_available_date: first_date.strftime("%Y-%m-%d"),
      second_available_date: second_date.strftime("%Y-%m-%d"),
    })
    hash.merge!({
      prices_by_days: prices_by_days_cents,
      prices_by_nights: prices_by_nights_cents,
      minimum_booking_days: minimum_booking_days,
      continuous_dates: action_continuous_dates_booking,
      action_daily_booking: day_booking?,
    }) if night_booking? || day_booking?
    hash.merge!({
      minimum_booking_minutes: minimum_booking_minutes,
      earliest_open_minute: availability.earliest_open_minute,
      latest_close_minute: availability.latest_close_minute,
      action_hourly_booking: true,
      prices_by_hours: prices_by_hours_cents,
      hourly_availability_schedule_url: Rails.application.routes.url_helpers.hourly_availability_schedule_listing_reservations_path(transactable, format: :json),
      hourly_availability_schedule: { I18n.l(first_date.to_date, format: :short) => hourly_availability_schedule(first_date).as_json },
    }) if hour_booking?
    hash
  end

  def availability_template_attributes=(template_attributes)
    if template_attributes.present?
      if template_attributes["id"].present?
        self.availability_template.assign_attributes template_attributes
      else
        template_attributes.merge!({
          name: 'Custom transactable availability',
          parent: self
        })
        self.availability_template = AvailabilityTemplate.new(template_attributes)
      end
    end
  end

  private

  def booking_availability
    unless (availability && availability.consecutive_days_open?)
      errors.add(:availability_template, I18n.t('activerecord.errors.models.transactable.attributes.no_consecutive_days'))
    end
  end

  def availability_status_between(start_date, end_date)
    AvailabilityRule::ListingStatus.new(self, start_date, end_date)
  end

end