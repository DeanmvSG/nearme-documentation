class Webhooks::StripeConnectsController < Webhooks::BaseWebhookController

  def webhook
    if request.post? && merchant_account = MerchantAccount::StripeConnectMerchantAccount.find_by(internal_payment_gateway_account_id: params[:user_id])
      begin
        event = @payment_gateway.parse_webhook(params[:id], merchant_account.data[:secret_key])
        case event.type
        when 'account.updated'
          account = @payment_gateway.retrieve_account(event.data.object.id)
          merchant_account.skip_validation = true
          merchant_account.change_state_if_needed(account) do |new_state|
            case new_state
            when 'verified'
              WorkflowStepJob.perform(WorkflowStep::PaymentGatewayWorkflow::MerchantAccountApproved, merchant_account.id)
            when 'failed'
              WorkflowStepJob.perform(WorkflowStep::PaymentGatewayWorkflow::MerchantAccountDeclined, merchant_account.id, "Missing fields: #{account.verification.fields_needed.join(', ')}")
            end
          end
          if account.verification.fields_needed.present?
            merchant_account.update_column :data, merchant_account.data.merge(fields_needed: account.verification.fields_needed)
          end
        end
      ensure
        merchant_account.webhooks.create!(response: params.to_yaml)
      end
    end
  ensure
    render nothing: true
  end

  protected

  def payment_gateway_class
    PaymentGateway::StripeConnectPaymentGateway
  end

end

