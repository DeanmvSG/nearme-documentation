require 'active_merchant/billing/gateways/paypal/paypal_express_response'

class Payout < ActiveRecord::Base
  auto_set_platform_context
  scoped_to_platform_context
  acts_as_paranoid
  has_paper_trail

  belongs_to :instance
  belongs_to :payment_gateway
  belongs_to :reference, -> { with_deleted }, polymorphic: true

  scope :successful, -> { where(:success => true) }
  scope :pending, -> { where(:pending => true) }
  scope :failed, -> { where(:pending => false, :success => false) }

  monetize :amount, with_model_currency: :currency
  serialize :response, Hash

  attr_encrypted :response, :key => DesksnearMe::Application.config.secret_token, marshal: true

  def payout_pending(response)
    self.pending = true
    self.response = response.to_yaml
    save!
  end

  def payout_successful(response = nil)
    self.success = true
    self.pending = false
    self.response = response
    save!
    self.reference.try(:success!)
  end

  def payout_failed(response)
    self.success = false
    self.pending = false
    self.response = response.to_yaml
    save!
    self.reference.try(:fail!)
  end

  alias_method :decrypted_response, :response

  def failure_message
    response.failure_message
  end

  def should_be_verified_after_time?
    pending? && response.should_be_verified_after_time?
  end

  def verify_after_time_arguments
    response.verify_after_time_arguments
  end

  def failed?
    !success && !pending
  end

  def confirmation_url
    response.confirmation_url if pending? && !reference.transferred?
  end

  def amount_money
    Money.new(amount, currency)
  end

end
