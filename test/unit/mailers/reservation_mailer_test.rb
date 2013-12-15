require 'test_helper'

class ReservationMailerTest < ActiveSupport::TestCase

  include Rails.application.routes.url_helpers

  setup do
    stub_mixpanel
    @user = FactoryGirl.create(:user)
    @reservation = FactoryGirl.build(:reservation, user: @user)
    @reservation.periods = [ReservationPeriod.new(:date => Date.parse("2012/12/12")), ReservationPeriod.new(:date => Date.parse("2012/12/13"))]
    @reservation.save!

    @platform_context = PlatformContext.new
    PlatformContext.any_instance.stubs(:domain).returns(FactoryGirl.create(:domain, :name => 'custom.domain.com'))
    @expected_dates = "Wednesday, December 12 &ndash; Thursday, December 13"
  end

  test "#notify_guest_of_cancellation_by_host" do
    mail = ReservationMailer.notify_guest_of_cancellation_by_host(@platform_context, @reservation)
    subject = "[#{@platform_context.decorate.name}] Your booking for '#{@reservation.listing.name}' at #{@reservation.location.street} was cancelled by the host"

    assert_contains @reservation.owner.first_name, mail.html_part.body
    assert_contains @reservation.listing.name, mail.html_part.body
    assert_equal [@reservation.owner.email], mail.to
    assert_equal subject, mail.subject
    assert_equal [@platform_context.decorate.support_email], mail.bcc
  end

  test "#notify_guest_of_cancellation_by_guest" do
    mail = ReservationMailer.notify_guest_of_cancellation_by_guest(@platform_context, @reservation)
    subject = "[#{@platform_context.decorate.name}] You just cancelled a booking"

    assert_contains @reservation.owner.first_name, mail.html_part.body
    assert_equal [@reservation.owner.email], mail.to
    assert_equal subject, mail.subject
    assert_equal [@platform_context.decorate.support_email], mail.bcc
  end

  test "#notify_guest_of_confirmation" do
    mail = ReservationMailer.notify_guest_of_confirmation(@platform_context, @reservation)

    assert_contains @reservation.listing.creator.name, mail.html_part.body
    assert_contains @expected_dates, mail.html_part.body

    assert_equal [@reservation.owner.email], mail.to
    assert_equal [@platform_context.decorate.support_email], mail.bcc
  end

  test "#notify_guest_of_expiration" do
    mail = ReservationMailer.notify_guest_of_expiration(@platform_context, @reservation)

    assert_contains @reservation.owner.first_name, mail.html_part.body
    assert_contains @reservation.listing.name, mail.html_part.body

    assert_equal [@reservation.owner.email], mail.to
    assert_equal [@platform_context.decorate.support_email], mail.bcc
  end

  test "#notify_guest_of_rejection" do
    mail = ReservationMailer.notify_guest_of_rejection(@platform_context, @reservation)

    assert_contains @reservation.listing.name, mail.html_part.body

    assert_equal [@reservation.owner.email], mail.to
    assert_equal "[#{@platform_context.decorate.name}] Can we help, #{@reservation.owner.first_name}?", mail.subject
    assert_equal [@platform_context.decorate.support_email], mail.bcc
  end

  test "#notify_host_of_rejection" do
    mail = ReservationMailer.notify_host_of_rejection(@platform_context, @reservation)

    assert_contains @reservation.listing.name, mail.html_part.body

    assert_equal [@reservation.listing.administrator.email], mail.to
    assert_equal "[#{@platform_context.decorate.name}] Can we help, #{@reservation.listing.administrator.first_name}?", mail.subject
    assert_equal [@platform_context.decorate.support_email, @reservation.listing.location.email], mail.bcc
  end

  test "#notify_guest_with_confirmation" do
    mail = ReservationMailer.notify_guest_with_confirmation(@platform_context, @reservation)

    assert_contains @reservation.listing.name, mail.html_part.body
    assert_equal [@reservation.owner.email], mail.to
    assert_equal [@platform_context.decorate.support_email], mail.bcc
  end

  test "#notify_host_of_cancellation_by_guest" do
    mail = ReservationMailer.notify_host_of_cancellation_by_guest(@platform_context, @reservation)

    assert_contains @reservation.listing.creator.name, mail.html_part.body
    assert_equal [@reservation.listing.creator.email], mail.to
    assert_equal [@platform_context.decorate.support_email, @reservation.listing.location.email], mail.bcc
  end

  test "#notify_host_of_cancellation_by_host" do
    mail = ReservationMailer.notify_host_of_cancellation_by_host(@platform_context, @reservation)

    assert_contains @reservation.listing.administrator.first_name, mail.html_part.body
    assert_equal [@reservation.listing.administrator.email], mail.to
    assert_equal [@platform_context.decorate.support_email, @reservation.listing.location.email], mail.bcc
  end

  test "#notify_host_of_confirmation" do
    mail = ReservationMailer.notify_host_of_confirmation(@platform_context, @reservation)

    assert_contains @reservation.listing.creator.name, mail.html_part.body
    assert_equal [@reservation.listing.creator.email], mail.to
    assert_equal [@platform_context.decorate.support_email, @reservation.listing.location.email], mail.bcc
  end

  test "#notify_host_of_expiration" do
    mail = ReservationMailer.notify_host_of_expiration(@platform_context, @reservation)

    assert_contains @reservation.listing.creator.name, mail.html_part.body
    assert_equal [@reservation.listing.creator.email], mail.to
    assert_equal [@platform_context.decorate.support_email, @reservation.listing.location.email], mail.bcc
  end

  test "#notify_host_with_confirmation" do
    # We freeze time for this test since we're asserting the presence of
    # a temporary login token. We rely on semantics that for any given expiry
    # time, two tokens are the same for the same user. This is somewhat of
    # a hack.
    Time.freeze do
      mail = ReservationMailer.notify_host_with_confirmation(@platform_context, @reservation)

      assert_contains manage_guests_dashboard_path(:token => @reservation.listing_creator.temporary_token), mail.html_part.body
      assert_contains @reservation.listing.creator.name, mail.html_part.body
      assert_contains @expected_dates, mail.html_part.body

      assert_equal [@reservation.listing.creator.email], mail.to
      assert_equal [@platform_context.decorate.support_email, @reservation.listing.location.email], mail.bcc
    end
  end

  test "#notify_host_without_confirmation" do
    mail = ReservationMailer.notify_host_without_confirmation(@platform_context, @reservation)

    assert_contains @reservation.listing.creator.name, mail.html_part.body
    assert_contains @expected_dates, mail.html_part.body
    assert_equal [@reservation.listing.creator.email], mail.to
    assert_equal [@platform_context.decorate.support_email, @reservation.listing.location.email], mail.bcc
  end

  test "#pre_booking" do
    mail = ReservationMailer.pre_booking(@platform_context, @reservation)

    assert_contains @reservation.listing.name, mail.html_part.body
    assert_equal [@reservation.owner.email], mail.to
    assert_equal "[#{@platform_context.decorate.name}] #{@reservation.owner.first_name}, your booking is tomorrow!", mail.subject
    assert_equal [@platform_context.decorate.support_email], mail.bcc
  end

  test "send to contact person if exists" do
    @reservation.listing.location.update_attribute(:administrator_id, FactoryGirl.create(:user, :email => 'maciek@example.com').id)
    ['notify_host_of_cancellation_by_guest', 'notify_host_of_cancellation_by_host', 'notify_host_of_confirmation', 'notify_host_of_expiration', 'notify_host_with_confirmation', 'notify_host_without_confirmation'].each do |method|
      mail = ReservationMailer.send(method, @platform_context, @reservation)
      assert_equal ['maciek@example.com'], mail.to, "Expected maciek@example.com, got #{mail.to} for #{method}"
    end
  end

  test 'include correct host in urls' do

    @reservation.listing.location.update_attribute(:administrator_id, FactoryGirl.create(:user, :email => 'maciek@example.com').id)
    ['notify_host_of_cancellation_by_guest', 'notify_host_of_cancellation_by_host', 'notify_host_of_confirmation', 'notify_host_of_expiration', 'notify_host_with_confirmation', 'notify_host_without_confirmation', 'pre_booking'].each do |method|
      mail = ReservationMailer.send(method, @platform_context, @reservation)
      assert_contains 'href="http://custom.domain.com/', mail.html_part.body
      assert_not_contains 'href="http://example.com', mail.html_part.body
      assert_not_contains 'href="/', mail.html_part.body
      assert_not_contains 'href="http://example.com', mail.text_part.body
      assert_not_contains 'href="/', mail.text_part.body
    end
  end

  test "has transactional email footer" do
    assert ReservationMailer.transactional?
  end
end

