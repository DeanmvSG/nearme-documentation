require 'braintree'

module ActiveMerchant
  module Billing
    class BraintreeCustomGateway < BraintreeBlueGateway

      def initialize(settings)
        settings.each { |k, v| Braintree::Configuration.send("#{k}=", v) if Braintree::Configuration.respond_to?("#{k}=") }
        super
      end

      # Braintree::WebhookNotification
      # https://github.com/braintree/braintree_ruby/blob/master/lib/braintree/webhook_notification.rb

      def verify_webhook(bt_challenge)
        Braintree::WebhookNotification.verify(bt_challenge)
      end

      def parse_webhook(bt_signature, bt_payload)
        Braintree::WebhookNotification.parse(bt_signature, bt_payload)
      end

      # Breaintree::MerchantAccount
      # https://github.com/braintree/braintree_ruby/blob/master/lib/braintree/merchant_account.rba

      def onboard!(hash)
        Braintree::MerchantAccount.create(hash)
      end

      def find_merchant(merchant_id)
        Braintree::MerchantAccount.find(merchant_id)
      end

      def update_onboard!(id, hash)
        Braintree::MerchantAccount.update(id, hash)
      end

      # Braintree::Transaction
      # https://github.com/braintree/braintree_ruby/blob/master/lib/braintree/transaction.rb

      def find_transaction(token)
        Braintree::Transaction.find(token)
      end

      def payment_settled?(token)
        find_transaction(token).try(:status) == 'settled'
      end

      def client_token
        @client_token ||= Braintree::ClientToken.generate
      end

      # TODO create_transaction_parameters method is temporal work around
      # Should be removed with upgrade of ActiveMerchant (activemerchant gem)
      # to the version higher that v1.60.0

      def create_transaction_parameters(money, credit_card_or_vault_id, options)
        super.tap do |parameters|
          parameters[:service_fee_amount] = options[:service_fee_amount] if options[:service_fee_amount]
          parameters[:payment_method_nonce] = options[:payment_method_nonce] if options[:payment_method_nonce]
        end
      end
    end
  end
end
