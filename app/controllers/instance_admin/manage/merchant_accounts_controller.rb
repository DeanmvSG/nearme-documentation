class InstanceAdmin::Manage::MerchantAccountsController < InstanceAdmin::Manage::BaseController

  skip_before_filter :check_if_locked

  def index
    params[:mode] ||= PlatformContext.current.instance.test_mode ? 'test' : 'live'

    @payment_gateways = PaymentGateway.payout_type.sort_by(&:name)
    merchant_account_scope = MerchantAccount.order('created_at DESC')
    merchant_account_scope = merchant_account_scope.where(state: params[:state]) if params[:state].present?
    merchant_account_scope = merchant_account_scope.where(payment_gateway_id: params[:payment_gateway_id]) if params[:payment_gateway_id].present?
    merchant_account_scope = merchant_account_scope.where(test: params[:mode] == 'test')

    @merchant_accounts = merchant_account_scope.paginate(per_page: 20, :page => params[:page])
  end

end
