class Manage::Listings::ReservationsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_listing
  before_filter :find_reservation

  def confirm
    if @reservation.confirmed?
      flash[:warning] = t('flash_messages.manage.reservations.reservation_already_confirmed')
    else
      if @reservation.confirm
        ReservationMailer.enqueue.notify_guest_of_confirmation(platform_context, @reservation)
        ReservationMailer.enqueue.notify_host_of_confirmation(platform_context, @reservation)
        begin
          ReservationSmsNotifier.notify_guest_with_state_change(@reservation).deliver
        rescue Twilio::REST::RequestError => e
          BackgroundIssueLogger.log_issue("[internal] twilio error - #{e.message}", "support@desksnear.me", "Reservation id: #{@reservation.id}, guest #{@reservation.owner.name} (#{@reservation.owner.id}). #{$!.inspect}")
        end
        event_tracker.confirmed_a_booking(@reservation)
        event_tracker.updated_profile_information(@reservation.owner)
        event_tracker.updated_profile_information(@reservation.host)
        event_tracker.track_event_within_email(current_user, request) if params[:track_email_event]
        flash[:success] = t('flash_messages.manage.reservations.reservation_confirmed')
      else
        flash[:error] = t('flash_messages.manage.reservations.reservation_not_confirmed')
      end
    end
    redirect_to manage_guests_dashboard_url
  end

  def rejection_form
  end

  def reject
    if @reservation.reject(rejection_reason)
      ReservationIssueLogger.rejected_with_reason @reservation, current_user if rejection_reason.present?
      ReservationMailer.enqueue.notify_guest_of_rejection(platform_context, @reservation)
      ReservationMailer.enqueue.notify_host_of_rejection(platform_context, @reservation)
      begin
        ReservationSmsNotifier.notify_guest_with_state_change(@reservation).deliver
      rescue Twilio::REST::RequestError => e
        BackgroundIssueLogger.log_issue("[internal] twilio error - #{e.message}", "support@desksnear.me", "Reservation id: #{@reservation.id}, guest #{@reservation.owner.name} (#{@reservation.owner.id}). #{$!.inspect}")
      end
      event_tracker.rejected_a_booking(@reservation)
      event_tracker.updated_profile_information(@reservation.owner)
      event_tracker.updated_profile_information(@reservation.host)
      flash[:deleted] = t('flash_messages.manage.reservations.reservation_rejected')
    else
      flash[:error] = t('flash_messages.manage.reservations.reservation_not_confirmed')
    end
    redirect_to manage_guests_dashboard_url
    render_redirect_url_as_json if request.xhr?
  end

  def host_cancel
    if @reservation.host_cancel
      ReservationMailer.enqueue.notify_guest_of_cancellation_by_host(platform_context, @reservation)
      ReservationMailer.enqueue.notify_host_of_cancellation_by_host(platform_context, @reservation)
      begin
        ReservationSmsNotifier.notify_guest_with_state_change(@reservation).deliver
      rescue Twilio::REST::RequestError => e
        BackgroundIssueLogger.log_issue("[internal] twilio error - #{e.message}", "support@desksnear.me", "Reservation id: #{@reservation.id}, guest #{@reservation.owner.name} (#{@reservation.owner.id}). #{$!.inspect}")
      end
      event_tracker.cancelled_a_booking(@reservation, { actor: 'host' })
      event_tracker.updated_profile_information(@reservation.owner)
      event_tracker.updated_profile_information(@reservation.host)
      flash[:deleted] = t('flash_messages.manage.reservations.reservation_cancelled')
    else
      flash[:error] = t('flash_messages.manage.reservations.reservation_not_confirmed')
    end
    redirect_to manage_guests_dashboard_url
  end

  private

  def find_listing
    @listing = current_user.listings.find(params[:listing_id])
  end

  def find_reservation
    @reservation = @listing.reservations.find(params[:id])
  end

  def current_event
    params[:event].downcase.to_sym
  end

  def rejection_reason
    params[:reservation][:rejection_reason] if params[:reservation] and params[:reservation][:rejection_reason]
  end
end

