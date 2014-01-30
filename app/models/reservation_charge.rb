class ReservationCharge < ActiveRecord::Base
  has_paper_trail
  acts_as_paranoid

  # === Associations
  belongs_to :reservation
  has_many :charge_attempts,
    :class_name => 'Charge',
    :as => :reference,
    :dependent => :destroy

  has_one :instance, through: :reservation

  # === Scopes
  # These payments have been attempted but failed during the charge attempt.
  # We can inspect the charge_attempts to see what the failure reason was
  # from the gateway response.
  scope :needs_payment_capture, -> {
    where(paid_at: nil).where("#{table_name}.failed_at IS NOT NULL")
  }

  scope :paid, -> {
    where("#{table_name}.paid_at IS NOT NULL")
  }

  scope :last_x_days, lambda { |days_in_past|
    where('DATE(reservation_charges.created_at) >= ? ', days_in_past.days.ago)
  }

  scope :needs_payment_transfer, -> {
    paid.where(payment_transfer_id: nil)
  }

  scope :total_by_currency, -> {
    paid.group('reservation_charges.currency').
      select('
        reservation_charges.currency,
        SUM(
          reservation_charges.subtotal_amount_cents
          + reservation_charges.service_fee_amount_guest_cents
        )
      ')
  }

  scope :for_instance, ->(instance) { joins(:instance).where(:'instances.id' => instance.id) }

  # === Callbacks
  before_validation :assign_currency
  after_create :capture

  validates :currency, presence: true

  # === Helpers
  monetize :subtotal_amount_cents
  monetize :service_fee_amount_guest_cents
  monetize :service_fee_amount_host_cents
  monetize :total_amount_cents

  def total_amount_cents
    subtotal_amount_cents + service_fee_amount_guest_cents
  end

  def amount
    total_amount
  end

  # Attempt to capture the payment through the billing gateway
  def capture
    return if paid?

    # Generates a ChargeAttempt with this record as the reference.
    billing_gateway.charge(
      amount: total_amount_cents,
      reference: self
    )

    touch(:paid_at)
    ReservationChargeTrackerJob.perform_later(reservation.date.end_of_day, reservation.id) 
  rescue Billing::CreditCardError
    # Needs to be retried at a later time...
    touch(:failed_at)
  end

  def paid?
    paid_at.present?
  end

  private

  def billing_gateway
    @billing_gateway ||= Billing::Gateway.new(instance).ingoing_payment(reservation.owner, currency)
  end

  def assign_currency
    self.currency ||= reservation.currency
  end
end
