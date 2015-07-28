module BuySellMarket::CheckoutHelper
  def paypal_express_gateway_available?(order)
    PaymentGateway::PaypalExpressPaymentGateway === current_instance.payment_gateway(order.seller_iso_country_code, order.currency)
  end
end
