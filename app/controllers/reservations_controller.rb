class ReservationsController < ApplicationController
  before_filter :authenticate_user!, :except => :new

  before_filter :only => [:user_cancel] do |controller|
    unless allowed_events.include?(controller.action_name)
      flash[:error] = t('flash_messages.reservations.invalid_operation')
      redirect_to redirection_path
    end
  end

  def user_cancel
    if reservation.user_cancel
      ReservationMailer.enqueue.notify_host_of_cancellation_by_guest(reservation)
      ReservationMailer.enqueue.notify_guest_of_cancellation_by_guest(reservation)
      event_tracker.cancelled_a_booking(reservation, { actor: 'guest' })
      event_tracker.updated_profile_information(reservation.owner)
      event_tracker.updated_profile_information(reservation.host)
      flash[:deleted] = t('flash_messages.reservations.reservation_cancelled')
    else
      flash[:error] = t('flash_messages.reservations.reservation_not_confirmed')
    end
    redirect_to redirection_path
  end

  def index
    redirect_to upcoming_reservations_path
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
    @reservations = reservations.not_archived.to_a.sort_by(&:date)

    event_tracker.track_event_within_email(current_user, request) if params[:track_email_event]
    render :index
  end

  def archived
    @reservations = reservations.archived.to_a.sort_by(&:date)
    render :index
  end

  def host_rating
    existing_host_rating = HostRating.where(reservation_id: reservation.id,
                                            author_id: current_user.id)

    if params[:track_email_event]
      event_tracker.track_event_within_email(current_user, request)
      params[:track_email_event] = nil
    end

    if existing_host_rating.blank?
      upcoming
    else
      flash[:notice] = t('flash_messages.host_rating.already_exists')
      redirect_to root_path
    end
  end

  def booking_successful
    upcoming
  end

  protected

  def reservations
    @reservations ||= current_user.reservations
  end

  def reservation
    begin
      @reservation ||= reservations.find(params[:id])
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
      bookings_dashboard_path
    else
      manage_guests_dashboard_path
    end
  end

end
