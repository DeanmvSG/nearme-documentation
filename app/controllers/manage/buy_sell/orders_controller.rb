class Manage::BuySell::OrdersController < Manage::BuySell::BaseController
  include Spree::Core::ControllerHelpers::StrongParameters

  before_filter :find_order, only: [:edit, :update, :destroy, :cancel, :resume, :approve]

  def index
    @orders = @company.orders.paginate(page: params[:page], per_page: 20)
  end

  def edit
  end

  def update
    if @order.update_from_params(params, permitted_checkout_attributes)
      redirect_to location_after_save, notice: t('flash_messages.manage.order.updated')
    else
      flash[:error] = t('flash_messages.manage.order.error_update')
      render :edit
    end
  end

  def destroy
    @order.destroy
    flash[:notice] = t('flash_messages.manage.order.deleted')
    redirect_to location_after_save
  end

  def cancel
    @order.cancel!
    flash[:success] = t('flash_messages.manage.order.canceled')
    redirect_to :back
  end

  def resume
    @order.resume!
    flash[:success] = t('flash_messages.manage.order.resumed')
    redirect_to :back
  end

  def approve
    @order.approved_by(current_user)
    flash[:success] = t('flash_messages.manage.order.approved')
    redirect_to :back
  end

  private

  def location_after_save
    manage_buy_sell_orders_path
  end

  def find_order
    @order = @company.orders.find_by_number(params[:id]).try(:decorate)
  end

  #TODO move params for checkout to secure params
  # def order_params
  #   params.require(:order).permit(secured_params.spree_order)
  # end
end
