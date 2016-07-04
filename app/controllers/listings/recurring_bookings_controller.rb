class Listings::RecurringBookingsController < ApplicationController


  before_filter :find_listing
  before_filter :require_login_for_recurring_booking, :only => [:review, :create]
  before_filter :build_recurring_booking_request, only: [:review, :create]
  before_filter :secure_payment_with_token, only: [:review]
  before_filter :load_payment_with_token, only: [:review]
  before_filter :find_recurring_booking, only: [:booking_successful]
  before_filter :find_current_country, only: [:review, :create]
  before_filter :set_section_name, only: [:review, :create]

  def review
    event_tracker.reviewed_a_recurring_booking(@recurring_booking_request.recurring_booking)
  end

  def load_payment_with_token
    if request.ssl? and params["payment_token"]
      user, recurring_booking_params = User::PaymentTokenVerifier.find_token(params["payment_token"])
      sign_in user
      params[:reservation_request] = recurring_booking_params.symbolize_keys!
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
    @recurring_booking = @recurring_booking_request.recurring_booking
    if @recurring_booking_request.process
      if @recurring_booking_request.confirm_reservations?
        WorkflowStepJob.perform(WorkflowStep::RecurringBookingWorkflow::CreatedWithoutAutoConfirmation, @recurring_booking.id)
        event_tracker.updated_profile_information(@recurring_booking.owner)
        event_tracker.updated_profile_information(@recurring_booking.host)
      else
        WorkflowStepJob.perform(WorkflowStep::RecurringBookingWorkflow::CreatedWithAutoConfirmation, @recurring_booking_request.recurring_booking.id)
      end

      event_tracker.requested_a_recurring_booking(@recurring_booking)
      card_message = t('flash_messages.reservations.credit_card_will_be_charged')
      flash[:notice] = t('flash_messages.reservations.reservation_made', message: card_message)

      redirect_to booking_successful_dashboard_user_recurring_booking_path(@recurring_booking)
    else
      render :review
    end
  end

  def booking_successful
  end

  def hourly_availability_schedule
    schedule = if params[:date].present?
      date = Date.parse(params[:date])
      @listing.action_type.hourly_availability_schedule(date).as_json
    end

    render :json => schedule.presence || {}
  end

  private

  def require_login_for_recurring_booking
    unless user_signed_in?
      redirect_to new_user_registration_path(return_to: @listing.decorate.show_path)
    end
  end

  def find_listing
    @listing = Transactable.find(params[:listing_id])
  end

  def find_recurring_booking
    @recurring_booking = @listing.recurring_bookings.find(params[:id])
  end

  def build_recurring_booking_request
    attributes = params[:reservation_request] || {}
    @recurring_booking_request = RecurringBookingRequest.new(
      @listing,
      current_user,
      platform_context,
      recurring_booking_request_params.merge({ start_on: attributes[:start_on].to_date || attributes[:dates].try(:to_date) })
    )
  end

  def recurring_booking_request_params
     params.require(:reservation_request).permit(secured_params.recurring_booking_request(@listing.transactable_type.reservation_type))
  end

  def set_section_name
    @section_name = 'reservations reservations-review'
  end
end
