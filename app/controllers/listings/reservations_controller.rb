class Listings::ReservationsController < ApplicationController

  skip_before_filter :filter_out_token, only: [:return_express_checkout, :cancel_express_checkout]
  skip_before_filter :log_out_if_token_exists, only: [:return_express_checkout, :cancel_express_checkout]

  before_filter :secure_payment_with_token, :only => [:review, :address]
  before_filter :load_payment_with_token, :only => [:review, :address]
  before_filter :find_listing
  before_filter :find_reservation, only: [:booking_successful, :remote_payment, :booking_failed]
  before_filter :build_reservation_request, :only => [:review, :address, :create, :store_reservation_request, :express_checkout]
  before_filter :require_login_for_reservation, :only => [:review, :create, :address]
  before_filter :find_current_country, :only => [:review, :create, :address]
  before_filter :prepare_for_review, only: [:review, :address]

  def review
    if @listing.possible_delivery?
      initialize_shipping_address
      render :address and return
    end
  end

  def address
    shippo_settings_valid = true
    company_address_valid = true

    # We call shippo_api_token_present before checking shipping_address.valid? because that method may fail with an error if shippo settings are not correct and we
    # want the user to know that instead of throwing an error page
    if @reservation_request.delivery_type == 'pick_up' || ((shippo_settings_valid = ShippoApi::ShippoApi.shippo_api_token_present?) && @reservation_request.reservation.shipments.first.shipping_address.valid? && (company_address_valid = @reservation_request.reservation.shipments.first.valid_sending_company_address?(@reservation_request.reservation)))
      render :review and return
    end

    if !shippo_settings_valid
      flash.now[:error] = t('reservations.mpo_shipping_settings_not_valid')
    elsif !company_address_valid
      flash.now[:error] = t('reservations.company_address_not_valid')
    end

    @errors = @reservation_request.reservation.shipments.first.shipping_address.errors
  end

  def load_payment_with_token
    if request.ssl? and params["payment_token"]
      user, reservation_params = User::PaymentTokenVerifier.find_token(params["payment_token"])
      sign_in user
      params[:reservation_request] = reservation_params.symbolize_keys!
    end
  end

  def secure_payment_with_token
    if require_ssl?
      verifier = User::PaymentTokenVerifier.new(current_user, params[:reservation_request])
      @token = verifier.generate
      @url = url_for(platform_context.secured_constraint)
      render 'post_redirect'
    end
  end

  def create
    @reservation = @reservation_request.reservation
    if @reservation_request.process
      if @reservation.payment.remote_payment?
        redirect_to remote_payment_dashboard_user_reservation_path(@reservation, host: platform_context.decorate.host)
      elsif @reservation.payment.express_checkout_payment? && @reservation.payment.express_checkout_redirect_url
        redirect_to @reservation.payment.express_checkout_redirect_url
      else
        event_tracker.updated_profile_information(@reservation.owner)
        event_tracker.updated_profile_information(@reservation.host)
        event_tracker.requested_a_booking(@reservation)

        card_message = @reservation.payment.credit_card_payment? ? t('flash_messages.reservations.credit_card_will_be_charged') : ''
        flash[:notice] = t('flash_messages.reservations.reservation_made', message: card_message)
        redirect_to booking_successful_dashboard_user_reservation_path(@reservation, host: platform_context.decorate.host)
      end
    else
      render :review
    end
  end

  def return_express_checkout
    payment = Payment.find_by_express_token!(params[:token])
    payment.express_payer_id = params[:PayerID]
    reservation = payment.payable
    if payment.authorize
      event_tracker.updated_profile_information(reservation.owner)
      event_tracker.updated_profile_information(reservation.host)
      event_tracker.requested_a_booking(reservation)

      redirect_to booking_successful_dashboard_user_reservation_path(reservation, host: platform_context.decorate.host)
    else
      redirect_to booking_failed_dashboard_user_reservation_path(reservation, host: platform_context.decorate.host)
    end
  end

  def cancel_express_checkout
    payment = Payment.find_by_express_token!(params[:token])
    flash[:error] = t('flash_messages.reservations.booking_failed')
    reservation = payment.payable
    redirect_to location_listing_path(reservation.listing.location, reservation.listing), status: 301
  end

  # Renders remote payment form
  def remote_payment
    @billing_gateway = @reservation.instance.payment_gateway(@reservation.listing.company.iso_country_code, @reservation.currency)
    @billing_gateway.set_payment_data(@reservation)
  end

  def hourly_availability_schedule
    schedule = if params[:date].present?
      date = Date.parse(params[:date])
      @listing.hourly_availability_schedule(date).as_json
    end

    render :json => schedule.presence || {}
  end

  # Store the reservation request in the session so that it can be restored when returning to the listings controller.
  def store_reservation_request
    session[:stored_reservation_location_id] = @listing.location.id
    session[:stored_reservation_trigger] ||= {}
    session[:stored_reservation_trigger]["#{@listing.location.id}"] = params[:commit]

    # Marshals the booking request parameters into a better structured hash format for transmission and
    # future assignment to the Bookings JS controller.
    #
    # Returns a Hash of listing id's to hash of date & quantity values.
    #  { '123' => { 'date' => '2012-08-10', 'quantity => '1' }, ... }
    session[:stored_reservation_bookings] = {
      @listing.id => {
        quantity: @reservation_request.reservation.quantity,
        dates: @reservation_request.reservation.periods.map(&:date_with_time),
        start_minute: @reservation_request.start_minute,
        end_minute: @reservation_request.end_minute,
        book_it_out: @reservation_request.book_it_out,
        exclusive_price: @reservation_request.exclusive_price,
        guest_notes: @reservation_request.reservation.guest_notes
      }
    }
    head 200 if params[:action] == 'store_reservation_request'
  end

  private

  def initialize_shipping_address
    user_last_address = current_user.shipping_addresses.last.try(:dup)
    @reservation_request.reservation.shipments.new(
      shipping_address:  user_last_address || ShippingAddress.new(email: current_user.email, phone: current_user.full_mobile_number)
    )
  end

  def prepare_for_review
    build_approval_request_for_object(current_user)
    reservations_service.build_documents
    event_tracker.reviewed_a_booking(@reservation_request.reservation)
  end

  def require_login_for_reservation
    unless user_signed_in?
      store_reservation_request
      redirect_to new_user_registration_path(return_to: location_url(@listing.location, @listing, restore_reservations: true))
    end
  end

  def find_listing
    @listing = Transactable.find(params[:listing_id])
  end

  def find_reservation
    @reservation = @listing.reservations.find(params[:id])
  end

  def build_reservation_request
    params[:reservation_request][:waiver_agreement_templates] ||= {}
    params[:reservation_request][:waiver_agreement_templates] = params[:reservation_request][:waiver_agreement_templates].select { |k, v| v == "1" }.keys
    params[:reservation_request][:payment][:payment_method_nonce] = params.delete(:payment_method_nonce) if params[:reservation_request][:payment]
    params[:reservation_request][:documents] = params[:reservation_request][:documents_attributes]

    @reservation_request = ReservationRequest.new(
      @listing,
      current_user,
      reservation_request_params,
      params[:reservation_request][:checkout_extra_fields]
    )
  end

  def origin_domain?
    session[:origin_domain]
  end

  def clear_origin_domain
    session.delete(:origin_domain) if origin_domain?
  end

  def origin_domain
    session[:origin_domain] || request.host
  end

  def set_origin_domain(domain)
    session[:origin_domain] = domain
  end

  def reservations_service
    @reservations_service ||= Listings::ReservationsService.new(current_user, @reservation_request, params)
  end

  def reservation_request_params
     params.require(:reservation_request).permit(secured_params.reservation_request)
  end
end

