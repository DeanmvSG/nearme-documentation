class PaymentGateway::WorldpayPaymentGateway < PaymentGateway
  include PaymentGateway::ActiveMerchantGateway

  def self.settings
    { login: "" }
  end

  def self.active_merchant_class
    ActiveMerchant::Billing::WorldpayGateway
  end

  def refund_identification(charge)

  end
end

