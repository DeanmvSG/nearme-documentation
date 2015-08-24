class PaymentTransfer < ActiveRecord::Base
  has_paper_trail
  acts_as_paranoid
  auto_set_platform_context
  scoped_to_platform_context

  FREQUENCIES = %w(monthly fortnightly weekly semiweekly daily)
  DEFAULT_FREQUENCY = "fortnightly"

  belongs_to :company
  belongs_to :instance
  belongs_to :partner
  belongs_to :payment_gateway

  has_many :payments, :dependent => :nullify

  has_many :payout_attempts,
    -> { order 'created_at ASC' },
    :class_name => 'Payout',
    :as => :reference,
    :dependent => :nullify

  after_create :assign_amounts_and_currency
  after_create :payout

  scope :pending, -> {
    where(transferred_at: nil)
  }

  scope :transferred, -> {
    where("#{table_name}.transferred_at IS NOT NULL")
  }

  scope :last_x_days, lambda { |days_in_past|
    where("DATE(#{table_name}.created_at) >= ? ", days_in_past.days.ago)
  }

  validate :validate_all_charges_in_currency

  # Amount is the amount we're transferring to the Host from payments we've
  # received for their listings.
  #
  # Note that this is the gross amount excluding the service fee that we charged
  # to the end user. The service fee is our cut of the revenue.
  monetize :total_service_fee_cents, with_model_currency: :currency
  monetize :amount_cents, with_model_currency: :currency
  monetize :service_fee_amount_guest_cents, with_model_currency: :currency
  monetize :service_fee_amount_host_cents, with_model_currency: :currency
  monetize :gross_amount_cents, with_model_currency: :currency

  # This is the gross amount of revenue received from the charges included in
  # this payout - including the service fees recieved.
  def gross_amount_cents
    amount_cents + service_fee_amount_guest_cents + service_fee_amount_host_cents
  end

  # Whether or not we have executed the transfer to the hosts bank account.
  def transferred?
    transferred_at.present?
  end

  def mark_transferred
    touch(:transferred_at)
  end

  def company_including_deleted
    Company.with_deleted.find(company_id)
  end

  # Attempt to payout through the billing gateway
  def payout

    return if !billing_gateway.present?
    return if transferred?
    return if amount <= 0

    # Generates a ChargeAttempt with this record as the reference.
    payout = billing_gateway.payout(
      company,
      amount: amount,
      reference: self,
      payment_gateway_mode: payment_gateway_mode
    )


    if payout.success
      touch(:transferred_at)
    end
  end

  def pending?
    payout_attempts.last && payout_attempts.last.pending? && payout_attempts.last.should_be_verified_after_time?
  end

  def failed?
    payout_attempts.last.present? && !payout_attempts.last.pending? && !payout_attempts.last.success?
  end

  def fail!
    self.update_column(:transferred_at, nil) if self.payout_attempts.reload.successful.count.zero? && persisted?
  end

  def success!
    if (payout = self.payout_attempts.reload.successful.first).present? && persisted?
      self.update_column(:transferred_at, payout.created_at)
    end
  end

  def payout_processor
    billing_gateway
  end

  def possible_automated_payout_not_supported?
    # true if instance makes it possible to make automated payout for given currency, but company does not support it
    # false if either company can process this payment transfer automatically or instance does not support it
    billing_gateway.try(:supports_payout?) && company.merchant_accounts.where(payment_gateway: billing_gateway).count.zero?
  end

  def total_service_fee_cents
    self.service_fee_amount_host_cents + self.service_fee_amount_guest_cents
  end

  private

  def assign_amounts_and_currency
    self.currency = payments.first.try(:currency)
    self.service_fee_amount_host_cents = payments.inject(0) { |sum, rc| sum += rc.final_service_fee_amount_host_cents }
    self.amount_cents = payments.all.inject(0) { |sum, rc| sum += rc.subtotal_amount_cents_after_refund } - self.service_fee_amount_host_cents
    self.service_fee_amount_guest_cents = payments.inject(0) { |sum, rc| sum += rc.final_service_fee_amount_guest_cents }
    self.save!
  end

  def validate_all_charges_in_currency
    unless payments.map(&:currency).uniq.length <= 1
      errors.add :currency, 'all paid out payments must be in the same currency'
    end
  end

  def billing_gateway
    if @billing_gateway.nil?
      concrete_payment_gateway = payment_gateway || instance.payment_gateway(company.iso_country_code, currency)
      @billing_gateway = if concrete_payment_gateway.try(:supports_payout?)
                           concrete_payment_gateway
                           # this is hack for now - currently we might accept payments via Stripe, but do payout via PayPal
                         else
                           concrete_payment_gateway = instance.payment_gateways.find do |pg|
                             pg.supports_payout? && pg.supports_currency?(currency) && pg.class.supported_countries.include?(company.iso_country_code)
                           end
                           concrete_payment_gateway
                         end
    end
    @billing_gateway
  end

end
