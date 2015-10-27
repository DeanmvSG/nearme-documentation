FactoryGirl.define do
  factory :payment_gateway do
    test_settings { {api_key: "present"} }
    live_settings { {api_key: "present"} }

    after :build do |payment_gateway, payment_methods|
      build_active_payment_methods(payment_gateway)
    end

    before(:create) do |payment_gateway|
      payment_gateway.payment_countries << (Country.find_by_iso("US") || FactoryGirl.create(:country_us))
    end

    before(:create) do |payment_gateway|
      payment_gateway.payment_currencies << (Currency.find_by_iso_code("USD") || FactoryGirl.create(:currency_us))
    end

    after :create do |payment_gateway|
      payment_gateway.update_attributes(test_active: true, live_active: true)
    end

    factory :paypal_payment_gateway, class: PaymentGateway::PaypalPaymentGateway do
      before(:create) do |payment_gateway|
        payment_gateway.payment_currencies << (Currency.find_by_iso_code("JPY") || FactoryGirl.create(:currency_jpy))
      end

      test_settings {
        {
          email: 'sender_test@example.com',
          login: 'john_test',
          password: 'pass_test',
          signature: 'sig_test',
          app_id: 'app-123_test'
        }
      }
      live_settings {
        {
          email: 'sender_live@example.com',
          login: 'john_live',
          password: 'pass_live',
          signature: 'sig_live',
          app_id: 'app-123_live'
        }
      }
    end

    factory :paypal_adaptive_payment_gateway, class: PaymentGateway::PaypalAdaptivePaymentGateway do
      test_settings {
        {
          email: 'sender_test@example.com',
          login: 'john_test',
          password: 'pass_test',
          signature: 'sig_test',
          app_id: 'app-123_test'
        }
      }
      live_settings {
        {
          email: 'sender_live@example.com',
          login: 'john_live',
          password: 'pass_live',
          signature: 'sig_live',
          app_id: 'app-123_live'
        }
      }
    end


    factory :paypal_express_payment_gateway, class: PaymentGateway::PaypalExpressPaymentGateway do
      test_settings {
        {
          email: 'sender_test@example.com',
          login: 'john_test',
          password: 'pass_test',
          signature: 'sig_test',
          app_id: 'app-123_test',
          partner_id: "2EWXNHVCGY3JL"
        }
      }
      live_settings {
        {
          email: 'sender_live@example.com',
          login: 'john_live',
          password: 'pass_live',
          signature: 'sig_live',
          app_id: 'app-123_live',
          partner_id: "2EWXNHVCGY3JL"
        }
      }
    end

    factory :paypal_express_chain_payment_gateway, class: PaymentGateway::PaypalExpressChainPaymentGateway do
      test_settings {
        {
          email: 'sender_test@example.com',
          login: 'john_test',
          password: 'pass_test',
          signature: 'sig_test',
          app_id: 'app-123_test',
          partner_id: "2EWXNHVCGY3JL"
        }
      }
      live_settings {
        {
          email: 'sender_live@example.com',
          login: 'john_live',
          password: 'pass_live',
          signature: 'sig_live',
          app_id: 'app-123_live',
          partner_id: "2EWXNHVCGY3JL"
        }
      }
    end

    factory :stripe_payment_gateway, class: PaymentGateway::StripePaymentGateway do
      test_settings { { login: 'sk_test_r0wxkPFASg9e45UIakAhgpru' } }
      live_settings { { login: 'sk_test_r0wxkPFASg9e45UIakAhgpru' } }
    end

    factory :fetch_payment_gateway, class: PaymentGateway::FetchPaymentGateway do

      before(:create) do |payment_gateway|
        payment_gateway.payment_countries = [Country.find_by_iso("NZ") || FactoryGirl.create(:country_nz)]
      end

      before(:create) do |payment_gateway|
        payment_gateway.payment_currencies = [Currency.find_by_iso_code("NZD") || FactoryGirl.create(:currency_nzd)]
      end

      test_settings { { account_id: '123456789', secret_key: '987654321' } }
      live_settings { { account_id: '123456789', secret_key: '987654321' } }
    end

    factory :braintree_payment_gateway, class: PaymentGateway::BraintreePaymentGateway do
      test_settings { { merchant_id: "123456789", public_key: "987654321", private_key: "321543", supported_currency: 'USD'} }
      live_settings { { merchant_id: "123456789", public_key: "987654321", private_key: "321543", supported_currency: 'USD'} }
    end

    factory :braintree_marketplace_payment_gateway, class: PaymentGateway::BraintreeMarketplacePaymentGateway do
      test_settings { { merchant_id: "123456789", public_key: "987654321", private_key: "321543", supported_currency: 'USD', master_merchant_account_id: 'master_id'} }
      live_settings { { merchant_id: "123456789", public_key: "987654321", private_key: "321543", supported_currency: 'USD', master_merchant_account_id: 'master_id'} }
    end

    factory :stripe_connect_payment_gateway, class: PaymentGateway::StripeConnectPaymentGateway do
      test_settings { {login: "123456789"} }
      live_settings { {login: "123456789"} }
    end

    factory :manual_payment_gateway, class: PaymentGateway::ManualPaymentGateway do
    end
  end
end

def build_active_payment_methods(payment_gateway)
  PaymentMethod::PAYMENT_METHOD_TYPES.each do |payment_method|
    if payment_gateway.send("supports_#{payment_method}_payment?")
      payment_gateway.payment_methods.build(payment_method_type: payment_method, active: true)
    end
  end
end
