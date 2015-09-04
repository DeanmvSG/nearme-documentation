class Webhooks::BaseWebhookController < ApplicationController
  skip_before_filter :redirect_if_marketplace_password_protected
  before_filter :find_payment_gateway

  protected

  def find_payment_gateway
    @payment_gateway ||= payment_gateway_class.first!
  end

  def payment_gateway_class
    raise NotImplementedError
  end
end
