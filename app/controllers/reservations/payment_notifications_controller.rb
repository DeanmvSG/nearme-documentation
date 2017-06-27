class Reservations::PaymentNotificationsController < ApplicationController
  skip_before_filter :redirect_if_marketplace_password_protected

  def create
    @reservation = Order.find(params[:reservation_id])
    if params.key?('payment_provider_verifier') && params['txn_status'] == '2'
      redirect_to booking_successful_dashboard_user_reservation_path(@reservation)
    elsif params.key?('verifier')
      @reservation.payment.payment_method = PaymentMethod.remote.last
      @reservation.payment.payment_response_params = params
      @reservation.charge_and_confirm!
      render nothing: true
    else
      redirect_to booking_failed_dashboard_user_reservation_path(@reservation)
    end
  end
end