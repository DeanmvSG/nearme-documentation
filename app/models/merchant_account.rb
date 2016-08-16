class MerchantAccount < ActiveRecord::Base
  include Encryptable

  auto_set_platform_context
  scoped_to_platform_context
  acts_as_paranoid

  attr_encrypted :response, marshal: true

  has_many :webhooks, as: :webhookable, dependent: :destroy
  has_many :payments
  has_one :payment_subscription, dependent: :destroy, as: :subscriber

  # Relates with Company
  belongs_to :merchantable, polymorphic: true
  belongs_to :instance
  belongs_to :payment_gateway

  belongs_to :company, foreign_key: :merchantable_id
  has_many :instance_clients, through: :company

  accepts_nested_attributes_for :payment_subscription, allow_destroy: true

  # need to mention specific merchant accounts after associations
  MERCHANT_ACCOUNTS = {
    'braintree_marketplace' => MerchantAccount::BraintreeMarketplaceMerchantAccount,
    'stripe_connect'        => MerchantAccount::StripeConnectMerchantAccount,
    'paypal'                => MerchantAccount::PaypalMerchantAccount,
    'paypal_adaptive'       => MerchantAccount::PaypalAdaptiveMerchantAccount,
    'paypal_express_chain'  => MerchantAccount::PaypalExpressChainMerchantAccount
  }

  validates_presence_of :merchantable_id, :merchantable_type, :unless => lambda { |ic| ic.merchantable.present? }
  validates_presence_of :payment_gateway
  validate :data_correctness

  delegate :supported_currencies, to: :payment_gateway

  scope :verified_on_payment_gateway, -> (payment_gateway_id) { verified.where('merchant_accounts.payment_gateway_id = ?', payment_gateway_id) }
  scope :pending,  -> { where(state: 'pending') }
  scope :verified, -> { where(state: 'verified') }
  scope :failed,   -> { where(state: 'failed') }
  scope :failed,   -> { where(state: 'voided') }
  scope :live,   -> { where(test: false) }
  scope :active,   -> { where(state: ['pending', 'verified']) }
  scope :mode_scope, -> (test_mode = PlatformContext.current.instance.test_mode? ){  test_mode ? where(test: true) : where(test: false) }
  scope :paypal_express_chain,   -> { where(type: "MerchantAccount::PaypalExpressChainMerchantAccount") }

  attr_accessor :skip_validation, :redirect_url

  before_create :set_test_mode_if_necessary
  before_create :onboard!
  before_update :update_onboard!, unless: lambda { |merchant_account| merchant_account.skip_validation }

  state_machine :state, initial: :pending do
    after_transition  any => :verified, do: :set_possible_payout!
    after_transition  :verified => :failed, do: :unset_possible_payout!

    event :to_pending do
      transition [:verified, :failed] => :pending
    end

    event :verify do
      transition [:pending, :failed] => :verified
    end

    event :failure do
      transition [:pending, :verified] => :failed
    end

    event :void do
      transition [:pending, :verified] => :voided
    end
  end

  def to_liquid
    @mechant_account_drop ||= MerchantAccountDrop.new(self)
  end

  def data_correctness(*args)
  end

  def onboard!(*args)
  end

  def void!
    # We use update_attribute to prevent validation errors
    update_attribute(:state, :void)
    unset_possible_payout!
  end

  def update_onboard!(*args)
  end

  def response_object
    YAML.load(response)
  end

  def client
    merchantable
  end

  def chain_payments?
    payment_gateway.supports_paypal_chain_payments?
  end

  def to_attr
    self.class.name.underscore.gsub("merchant_account/", '') + "_attributes"
  end

  def parital_location
    "dashboard/company/merchant_accounts/#{payment_gateway.type_name}"
  end

  def payment_subscription_attributes=(payment_subscription_attributes)
    super(payment_subscription_attributes.merge(subscriber: self))
  end

  def supports_currency?(currency)
    payment_gateway.payment_currencies.map(&:iso_code).include?(currency)
  end

  def set_possible_payout!
    if !self.test? && self.merchantable && self.payment_gateway
      transactables = self.merchantable.listings.where(currency: supported_currencies)
      transactables.update_all(possible_payout: true)
      ElasticBulkUpdateJob.perform Transactable, transactables.map{ |listing| [listing.id, { possible_payout: true }]}
    end

    true
  end

  def unset_possible_payout!
    if !self.test? && self.merchantable && self.payment_gateway
      self.merchantable.listings.update_all(possible_payout: false)
      self.merchantable.merchant_accounts.live.verified.each(&:set_possible_payout!)
      ElasticBulkUpdateJob.perform Transactable, self.merchantable.listings.map{ |listing| [listing.id, { possible_payout: false }]}
    end
    true
  end

  def redirect_url
    @redirect_url || Rails.application.routes.url_helpers.edit_dashboard_company_payouts_path
  end

  private

  def set_test_mode_if_necessary
    self.test = PlatformContext.current.instance.test_mode?
    true
  end

end

