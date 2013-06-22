class Reservation < ActiveRecord::Base
  PAYMENT_METHODS = {
    :credit_card => 'credit_card',
    :manual      => 'manual'
  }

  PAYMENT_STATUSES = {
    :paid => 'paid',
    :failed => 'failed',
    :pending => 'pending',
    :unknown => 'unknown'
  }

  belongs_to :listing
  belongs_to :owner, :class_name => "User"

  attr_accessible :cancelable, :confirmation_email, :date, :deleted_at, :listing_id,
    :owner_id, :periods, :state, :user, :comment, :quantity

  has_many :periods,
           :class_name => "ReservationPeriod",
           :inverse_of => :reservation,
           :dependent => :destroy

  has_many :charges, :as => :reference, :dependent => :nullify

  validates :periods, :length => { :minimum => 1 }
  validates :quantity, :numericality => { :greater_than_or_equal_to => 1 }
  validate :validate_all_dates_available, on: :create
  validate :validate_booking_selection, on: :create

  before_create :set_total_cost
  before_validation :set_currency, on: :create
  before_validation :set_default_payment_status, on: :create
  after_create :auto_confirm_reservation

  # TODO: Move code relating to expiry event from model to controller.
  after_create :schedule_expiry

  def perform_expiry!
    if unconfirmed?
      expire!

      # FIXME: This should be moved to a background job base class, as per ApplicationController.
      #        The event_tracker calls can be executed from the Job instance.
      #        i.e. Essentially compose this as a 'non-http request' controller.
      mixpanel_wrapper = MixpanelApi.new(MixpanelApi.mixpanel_instance, :current_user => owner)
      event_tracker = Analytics::EventTracker.new(mixpanel_wrapper)
      event_tracker.booking_expired(self)

      ReservationMailer.notify_guest_of_expiration(self).deliver
      ReservationMailer.notify_host_of_expiration(self).deliver
    end
  end

  def schedule_expiry
    Delayed::Job.enqueue Delayed::PerformableMethod.new(self, :perform_expiry!, nil), run_at: expiry_time
  end

  acts_as_paranoid

  monetize :total_amount_cents

  state_machine :state, :initial => :unconfirmed do
    after_transition :unconfirmed => :confirmed, :do => :attempt_payment_capture

    event :confirm do
      transition :unconfirmed => :confirmed
    end

    event :reject do
      transition :unconfirmed => :rejected
    end

    event :host_cancel do
      transition :confirmed => :cancelled
    end

    event :user_cancel do
      transition [:unconfirmed, :confirmed] => :cancelled
    end

    event :expire do
      transition :unconfirmed => :expired
    end
  end

  scope :on, lambda { |date|
    joins(:periods).
      where("reservation_periods.date" => date).
      where(:state => [:confirmed, :unconfirmed]).
      uniq
  }

  scope :upcoming, lambda {
    joins(:periods).
      where('reservation_periods.date >= ?', Date.today).
      uniq
  }

  scope :visible, lambda {
    without_state(:cancelled).upcoming
  }

  scope :not_rejected_or_cancelled, lambda {
    without_state(:cancelled, :rejected)
  }

  scope :cancelled, lambda {
    with_state(:cancelled)
  }

  validates_presence_of :payment_method, :in => PAYMENT_METHODS.values
  validates_presence_of :payment_status, :in => PAYMENT_STATUSES.values, :allow_blank => true

  delegate :location, to: :listing

  def user=(value)
    self.owner = value
    self.confirmation_email = value.email
  end

  def date=(value)
    periods.build :date => value
  end

  def date
    periods.sort_by(&:date).first.date
  end

  def last_date
    periods.sort_by(&:date).last.date
  end

  def cancelable?
    case
    when confirmed?, unconfirmed?
      # A reservation can be canceled if not already canceled and all of the dates are in the future
      !started?
    else
      false
    end
  end
  alias_method :cancelable, :cancelable?

  # Returns whether any of the reserved dates have started
  def started?
    periods.any? { |p| p.date <= Date.today }
  end

  def archived?
    rejected? or cancelled? or periods.all? {|p| p.date < Date.today}
  end

  def add_period(date, start_minute = nil, end_minute = nil)
    periods.build :date => date, :start_minute => start_minute, :end_minute => end_minute
  end

  def booked_on?(date)
    periods.detect { |period| period.date == date }
  end

  def total_amount_cents
    if persisted?
      super
    else
      calculate_total_cost
    end
  end

  def total_amount_dollars
    total_amount_cents/100.0
  end

  def total_negative_amount_dollars
    total_amount_dollars * -1
  end

  def total_days
    periods.size
  end

  # Number of desks booked accross all days
  def desk_days
    # NB: use of 'size' not 'count' here is deliberate - seats/periods may not be persisted at this point!
    (quantity || 0) * periods.size
  end

  def successful_payment_amount
    charges.where(:success => true).first.try(:amount) || 0.0
  end

  def balance
    successful_payment_amount - total_amount_cents
  end

  def credit_card_payment?
    payment_method == Reservation::PAYMENT_METHODS[:credit_card]
  end

  def manual_payment?
    payment_method == Reservation::PAYMENT_METHODS[:manual]
  end

  def currency
    super.presence || listing.currency
  end

  def free?
    total_amount <= 0
  end

  def paid?
    payment_status == PAYMENT_STATUSES[:paid]
  end

  def pending?
    payment_status == PAYMENT_STATUSES[:pending]
  end

  def should_expire!
    expire! if unconfirmed?
  end

  def expiry_time
    created_at + 24.hours
  end

  def price_calculator
    @price_calculator ||= if listing.hourly_reservations?
      HourlyPriceCalculator.new(self)
    else
      PriceCalculator.new(self)
    end
  end

  private

    def set_default_payment_status
      return if paid?

      self.payment_status = if free?
        PAYMENT_STATUSES[:paid]
      else
        PAYMENT_STATUSES[:pending]
      end
    end

    def calculate_total_cost
      price_calculator.price.try(:cents)
    end

    def set_total_cost
      self.total_amount_cents = calculate_total_cost
    end

    def set_currency
      self.currency = listing.currency
    end

    def auto_confirm_reservation
      confirm! unless listing.confirm_reservations?
    end

    def create_scheduled_expiry_task
      Delayed::Job.enqueue Delayed::PerformableMethod.new(self, :should_expire!, nil), run_at: expiry_time
    end

    def attempt_payment_capture
      return if manual_payment? || free? || paid?

      billing_gateway = owner.billing_gateway

      begin
        billing_gateway.charge(
          amount: total_amount_cents,
          currency: currency,
          reference: self
        )
        self.payment_status = PAYMENT_STATUSES[:paid]
      rescue User::BillingGateway::CardError
        # TODO: Need to handle re-attempting charge, etc.
        self.payment_status = PAYMENT_STATUSES[:failed]
      end

      save!
    rescue
    end

    def validate_all_dates_available
      invalid_dates = periods.reject(&:bookable?)
      if invalid_dates.any?
        errors.add(:base, "Unfortunately the following bookings are no longer available: #{invalid_dates.map(&:as_formatted_string).join(', ')}")
      end
    end

    def validate_booking_selection
      unless price_calculator.valid?
        errors.add(:base, "Booking selection does not meet requirements. A minimum of #{listing.minimum_booking_days} consecutive bookable days are required.")
      end
    end

end
