class Dashboard::Company::PayoutsController < Dashboard::Company::BaseController

  before_action :get_payment_gateway_data
  before_action :build_merchant_account

  def edit
  end

  def update
    if @company.update_attributes(company_params)
      flash[:success] = t('flash_messages.manage.payouts.updated')
    end

    render :edit
  end

  private

  def company_params
    params.require(:company).permit(secured_params.company)
  end

  def get_payment_gateway_data
    @payment_gateways = if current_instance.skip_company?
       current_user.payout_payment_gateways
    else
      @company.payout_payment_gateways
    end
  end

  def build_merchant_account
    @merchant_accounts = []
    @payment_gateways.each do |payment_gateway|
      merchant_account = @company.merchant_accounts.mode_scope.where(payment_gateway: payment_gateway).first_or_initialize(
        payment_gateway_id: payment_gateway.id,
        type: payment_gateway.merchant_account_type.to_s,
        test: current_instance.test_mode?
      )

      merchant_account.try(:initialize_defaults) if merchant_account.try(:new_record?)
      merchant_account.owners.build if merchant_account.respond_to?(:owners) && !merchant_account.owners.present?

      if payment_gateway.supports_host_subscription? && merchant_account.payment_subscription.blank?
        merchant_account.build_payment_subscription(
          payer: current_user,
          subscriber: merchant_account,
          payment_method_id: payment_gateway.payment_methods.credit_card.first.id
        )
      end

      @merchant_accounts << merchant_account
    end
  end
end

