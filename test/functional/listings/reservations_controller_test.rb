require 'test_helper'

class Listings::ReservationsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  context "making a booking" do

    setup do
      @listing = FactoryGirl.create(:listing_in_san_francisco)
      @user = FactoryGirl.create(:user)
      sign_in @user
      @tracker = Analytics::EventTracker.any_instance
      stub_request(:get, /.*api\.mixpanel\.com.*/)
    end

    should "track booking modal open" do
      @tracker.expects(:opened_booking_modal).with do |reservation|
        reservation == assigns(:reservation)
      end
      xhr :post, :review, booking_params_for(@listing)
      assert_response 200
    end

    should "track booking request" do
      @tracker.expects(:requested_a_booking).with do |reservation|
        reservation == assigns(:reservation)
      end
      xhr :post, :create, booking_params_for(@listing)
      assert_response 200
    end


  end

  context 'export' do

    setup do
      @listing = FactoryGirl.create(:listing, :name => 'ICS Listing')
      @reservation = FactoryGirl.build(:reservation_with_credit_card, :listing => @listing)
      @reservation.periods = []
      Timecop.freeze(Time.local(2013, 6, 28, 10, 5, 0))
      @reservation.add_period(DateTime.now.next_week.next_day(1))
      @reservation.add_period(DateTime.now.next_week.next_day(2))
      @reservation.add_period(DateTime.now.next_week.next_day(3))
      @reservation.save!
      sign_in @reservation.owner
      Rails.application.routes.url_helpers.stubs(:listing_reservation_url).returns("http://example.com/listings/1/reservations/1/export.ics")
    end

    should 'be exportable to .ics format' do
      get :export, :format => :ics, :listing_id => @reservation.listing.id, :id => @reservation.id
      assert_response :success
      assert_equal "text/calendar", response.content_type
      assert_equal [ "BEGIN:VCALENDAR", "VERSION:2.0", "CALSCALE:GREGORIAN", "METHOD:PUBLISH", "PRODID:iCalendar-Ruby",
        "BEGIN:VEVENT", "CREATED:080500", "DESCRIPTION:42 Wallaby Way - ICS Listing", "DTEND:20130701T170000", "DTSTAMP:20130628T100500",
        "DTSTART:20130701T090000", "CLASS:PUBLIC", "LAST-MODIFIED:080500", "LOCATION:42 Wallaby Way", "SEQUENCE:0", "SUMMARY:ICS Listing",
        "UID:http://example.com/listings/1/reservations/1/export.ics", "URL:http://example.com/listings/1/reservations/1/export.ics", "END:VEVENT",
        "BEGIN:VEVENT", "CREATED:080500", "DESCRIPTION:42 Wallaby Way - ICS Listing", "DTEND:20130702T170000", "DTSTAMP:20130628T100500",
        "DTSTART:20130702T090000", "CLASS:PUBLIC", "LAST-MODIFIED:080500", "LOCATION:42 Wallaby Way", "SEQUENCE:0", "SUMMARY:ICS Listing",
        "UID:http://example.com/listings/1/reservations/1/export.ics", "URL:http://example.com/listings/1/reservations/1/export.ics", "END:VEVENT",
        "BEGIN:VEVENT", "CREATED:080500", "DESCRIPTION:42 Wallaby Way - ICS Listing", "DTEND:20130703T170000", "DTSTAMP:20130628T100500",
        "DTSTART:20130703T090000", "CLASS:PUBLIC", "LAST-MODIFIED:080500", "LOCATION:42 Wallaby Way",
        "SEQUENCE:0", "SUMMARY:ICS Listing", "UID:http://example.com/listings/1/reservations/1/export.ics", "URL:http://example.com/listings/1/reservations/1/export.ics",
        "END:VEVENT", "END:VCALENDAR"], response.body.split("\r\n")
    end

    teardown do
      Timecop.return
    end
  end

  def booking_params_for(listing)
    {
      "listing_id" => @listing.id,
      "reservation" => {
      "dates" => [Chronic.parse('Monday')],
      "quantity"=>"1"
    }
    }
  end

end

