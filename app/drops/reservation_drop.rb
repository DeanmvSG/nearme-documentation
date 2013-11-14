class ReservationDrop < BaseDrop
  include ReservationsHelper

  def initialize(reservation)
    @reservation = reservation
  end

  def quantity
    @reservation.quantity
  end

  def hourly_summary
    hourly_summary_for_period(@reservation.periods.first)
  end

  def dates_summary
    selected_dates_summary(@reservation)
  end

  def subtotal_price
    reservation_subtotal_price(@reservation)
  end

  def service_fee
    reservation_service_fee(@reservation)
  end

  def total_price
    reservation_total_price(@reservation)
  end

  def pending?
    @reservation.pending?
  end

  def credit_cart_payment?
    @reservation.credit_card_payment?
  end

  def paid
    reservation_paid(@reservation)
  end

  def balance
    reservation_balance(@reservation)
  end

  def has_rejection_reason
    !@reservation.rejection_reason.to_s.empty?
  end

  def rejection_reason
    @reservation.rejection_reason
  end

  def search_url
    routes.search_url(q: location_query_string(@reservation.listing.location))
  end

  def guest_rating_reservation_url
    routes.guest_rating_url(@reservation.id, token: @reservation.listing.administrator.authentication_token)
  end

  def guest_rating_reservation_url_with_tracking
    routes.guest_rating_url(@reservation.id, token: @reservation.listing.administrator.authentication_token, track_email_event: true)
  end

  def host_rating_reservation_url
    routes.host_rating_url(@reservation.id, token: @reservation.owner.authentication_token)
  end

  def host_rating_reservation_url_with_tracking
    routes.host_rating_url(@reservation.id, token: @reservation.owner.authentication_token, track_email_event: true)
  end

  def export_to_ical_url
    routes.export_reservation_url(@reservation, format: :ics, token: @reservation.owner.authentication_token)
  end

  def created_at
    @reservation.created_at.strftime("%A,%e %B")
  end

  def owner
    @reservation.owner
  end

  def reservation_confirm_url
    routes.confirm_manage_listing_reservation_url(@reservation.listing, @reservation, :token => @reservation.listing.administrator.authentication_token)
  end 

  def reservation_confirm_url_with_tracking
    routes.confirm_manage_listing_reservation_url(@reservation.listing, @reservation, :token => @reservation.listing.administrator.authentication_token, :track_email_event => true)
  end

  def start_date
    @reservation.date.strftime('%b %e')
  end
end
