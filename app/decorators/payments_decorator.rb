class PaymentDecorator < Draper::Decorator
  include Draper::LazyHelpers
  delegate_all

  def alerts
    alerts_container = []

    if paid? && refunds.any?
      if should_retry_refund?
        alerts_container << I18n.t("decorators.payment.refund_retry_at", retry_at: l(self.retry_refund_at, format: :long))
      else
        alerts_container << I18n.t("decorators.payment.refund_failed")
      end
    end
    alerts_container
  end

  def payment_methods
    if is_free?
      payment_gateways.map(&:active_free_payment_methods)
    else
      payment_gateways.map(&:active_payment_methods)
    end.flatten.uniq
  end

  def host_payment_methods
    payment_gateways.map(&:active_payment_methods).flatten.uniq
  end

  def payment_gateways
    @payment_gateways ||= PlatformContext.current.instance.payment_gateways(company.iso_country_code, currency)
  end

  def self.collection_decorator_class
    PaginatingDecorator
  end
end

