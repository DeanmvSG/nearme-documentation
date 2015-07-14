class Dashboard::UserReservationsController < Dashboard::BaseController

  before_filter :only => [:user_cancel] do |controller|
    unless allowed_events.include?(controller.action_name)
      flash[:error] = t('flash_messages.reservations.invalid_operation')
      redirect_to redirection_path
    end
  end
  before_filter :reservation, only: [:booking_successful_modal, :booking_failed_modal]

  def user_cancel
    if reservation.user_cancel
      WorkflowStepJob.perform(WorkflowStep::ReservationWorkflow::GuestCancelled, reservation.id)
      event_tracker.cancelled_a_booking(reservation, { actor: 'guest' })
      event_tracker.updated_profile_information(reservation.owner)
      event_tracker.updated_profile_information(reservation.host)
      flash[:success] = t('flash_messages.reservations.reservation_cancelled')
    else
      flash[:error] = t('flash_messages.reservations.reservation_not_confirmed')
    end
    redirect_to redirection_path
  end

  def index
    redirect_to upcoming_dashboard_user_reservations_path
  end

  def export
    respond_to do |format|
      format.ics do
        render :text => ReservationIcsBuilder.new(reservation, current_user).to_s
      end
    end
  end

  def upcoming
    @reservation  = reservation if params[:id]
    @reservations = reservations.no_recurring.not_archived.to_a.sort_by(&:date)
    @recurring_bookings = recurring_bookings.not_archived.order(:start_on, :end_on)

    event_tracker.track_event_within_email(current_user, request) if params[:track_email_event]
    render :index
  end

  def archived
    @reservations = reservations.no_recurring.archived.to_a.sort_by(&:date)
    @recurring_bookings = recurring_bookings.archived.order(:start_on, :end_on)
    render :index
  end

  def booking_successful
    upcoming
  end

  def booking_failed
    upcoming
  end

  def booking_successful_modal
    render template: 'dashboard/user_reservations/booking_successful_modal', formats: [:html]
  end

  def booking_failed_modal
  end

  def remote_payment
    if reservation.paid?
      redirect_to booking_successful_dashboard_user_reservation_path(reservation)
    else
      setup_payment_gateway
      upcoming
    end
  end

  def remote_payment_modal
    setup_payment_gateway
  end

  def recurring_booking_successful
    @recurring_booking = current_user.recurring_bookings.find(params[:id])
    params[:id] = nil
    upcoming
  end

  def recurring_booking_successful_modal
  end

  protected

  def setup_payment_gateway
    res = reservation
    @billing_gateway = res.instance.payment_gateway(res.listing.company.iso_country_code, res.currency)
    @billing_gateway.set_payment_data(res)
  end

  def reservations
    @reservations ||= current_user.reservations
  end

  def recurring_bookings
    @recurring_bookings ||= current_user.recurring_bookings
  end

  def reservation
    begin
      @reservation ||= current_user.reservations.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      raise Reservation::NotFound
    end
  end

  def allowed_events
    ['user_cancel']
  end

  def current_event
    params[:event].downcase.to_sym
  end

  def redirection_path
    if @reservation.owner.id == current_user.id
      dashboard_user_reservations_path
    else
      dashboard_company_host_reservations_path
    end
  end

end
