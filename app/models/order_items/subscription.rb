class OrderItem::Subscription < OrderItem

  attr_encrypted :authorization_token, :payment_gateway_class

  belongs_to :platform_context_detail, :polymorphic => true
  belongs_to :transactable_pricing

  has_one :payment_subscription, as: :subscriber
  has_many :recurring_booking_periods, dependent: :destroy

  delegate :action, to: :transactable_pricing
  delegate :favourable_pricing_rate, :service_fee_guest_percent, :service_fee_host_percent, to: :action, allow_nil: true

  scope :upcoming, lambda { where('end_on > ?', Time.zone.now) }
  scope :not_archived, lambda { without_state(:cancelled_by_guest, :cancelled_by_host, :rejected, :expired).uniq }
  scope :visible, lambda { without_state(:cancelled_by_guest, :cancelled_by_host).upcoming }
  scope :not_rejected_or_cancelled, lambda { without_state(:cancelled_by_guest, :cancelled_by_host, :rejected) }
  scope :cancelled, lambda { with_state(:cancelled_by_guest, :cancelled_by_host) }
  scope :confirmed, lambda { with_state(:confirmed) }
  scope :rejected, lambda { with_state(:rejected) }
  scope :expired, lambda { with_state(:expired) }
  scope :cancelled_or_expired_or_rejected, lambda { with_state(:cancelled_by_guest, :cancelled_by_host, :rejected, :expired) }
  scope :archived, lambda { where('end_on < ? OR state IN (?)', Time.zone.today, ['rejected', 'expired', 'cancelled_by_host', 'cancelled_by_guest']).uniq }
  scope :needs_charge, -> (date) { with_state(:confirmed, :overdued).where('next_charge_date <= ?', date) }


  after_create :auto_confirm_reservation

  validates :owner_id, presence: true, unless: -> { owner.present? }

  state_machine :state, initial: :unconfirmed do
    before_transition unconfirmed: :confirmed do |recurring_booking, transaction|
      if recurring_booking.check_overbooking && recurring_booking.errors.empty? && period = recurring_booking.generate_next_period!
        period.generate_payment!
        true
      else
        false
      end
    end
    after_transition [:unconfirmed, :confirmed] => :cancelled_by_guest, do: :cancel
    after_transition confirmed: :cancelled_by_host, do: :cancel
    before_transition unconfirmed: :rejected do |recurring_booking, transition|
      recurring_booking.rejection_reason = transition.args[0]
    end

    after_transition confirmed: :overdued do |recurring_booking, transition|
      WorkflowStepJob.perform(WorkflowStep::RecurringBookingWorkflow::PaymentOverdue, recurring_booking.id)
    end

    after_transition overdued: :confirmed do |recurring_booking, transition|
      WorkflowStepJob.perform(WorkflowStep::RecurringBookingWorkflow::PaymentInformationUpdated, recurring_booking.id)
    end

    event :confirm do       transition unconfirmed: :confirmed;   end
    event :expire do        transition unconfirmed: :expired;   end
    event :reject do        transition unconfirmed: :rejected;   end
    event :host_cancel do   transition all => :cancelled_by_host;   end
    event :guest_cancel do  transition [:unconfirmed, :confirmed] => :cancelled_by_guest;   end
    event :overdue do       transition confirmed: :overdued;   end
    event :reconfirm do     transition overdued: :confirmed;   end
  end

  def check_overbooking
    if (transactable.quantity - transactable.recurring_bookings.with_state(:confirmed).count) > 0
      true
    else
      errors.add(:base, I18n.t('recurring_bookings.overbooked'))
      false
    end
  end

  def cancel
    update_attribute :end_on, paid_until
    if cancelled_by_guest?
      WorkflowStepJob.perform(WorkflowStep::RecurringBookingWorkflow::GuestCancelled, self.id)
    elsif cancelled_by_host?
      WorkflowStepJob.perform(WorkflowStep::RecurringBookingWorkflow::HostCancelled, self.id)
    end
  end

  def auto_confirm_reservation
    confirm! unless transactable.confirm_reservations?
  end

  def archived?
    rejected? || cancelled_by_guest? || cancelled_by_host?
  end

  def to_liquid
    @recurring_booking ||= RecurringBookingDrop.new(self)
  end

  def recalculate_next_charge_date
    RecurringBooking::NextDateFactory.get_calculator(transactable_pricing, self.next_charge_date).next_charge_date
  end

  def amount_calculator
    @amount_calculator ||= RecurringBooking::AmountCalculatorFactory.get_calculator(self)
  end

  def amount_calculator=(calculator)
    @amount_calculator = calculator
  end

  def recalculate_next_charge_date!
    self.update_attribute(:next_charge_date, recalculate_next_charge_date)
  end

  def generate_next_period!
    RecurringBooking.transaction do
      # Most likely next_charge_date would be Date.current, however
      # we do not want to rely on delayed_job being invoked on proper day.
      # If we invoke this job later than we should, we don't want to corrupt dates,
      # this is much more safer
      period_start_date = next_charge_date

      recalculate_next_charge_date!
      recurring_booking_periods.create!(
        service_fee_amount_guest_cents: amount_calculator.guest_service_fee.cents,
        service_fee_amount_host_cents: amount_calculator.host_service_fee.cents,
        subtotal_amount_cents: amount_calculator.subtotal_amount.cents,
        period_start_date: period_start_date,
        period_end_date: next_charge_date - 1.day,
        credit_card_id: credit_card_id,
        currency: currency
      ).tap do
        # to avoid cache issues if one would like to generate multiple periods in the future
        self.amount_calculator = nil
      end
    end
  end

  def bump_paid_until_date!
    # if someone skips payment for October, but will pay for November, we do not want to set paid_until date to November. We will set it to November after
    # he pays for October.
    update_attribute(:paid_until, recurring_booking_periods.paid.maximum(:period_end_date)) unless recurring_booking_periods.unpaid.count > 0
  end

  def total_amount_calculator
    @total_amount_calculator ||= RecurringBooking::SubscriptionPriceCalculator.new(self)
  end

  def monthly?
    transactable_pricing.unit == 'subscription_month'
  end

  # def expires_at
  #   created_at + transactable.hours_to_expiration.to_i.hours
  # end

end