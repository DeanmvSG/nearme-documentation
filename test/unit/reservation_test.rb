require 'test_helper'
require 'reservations_helper'

class ReservationTest < ActiveSupport::TestCase
  include ReservationsHelper

  test "it has a listing" do
    @reservation = Reservation.new
    @reservation.listing = FactoryGirl.create(:listing)

    assert @reservation.listing
  end

  test "it has an owner" do
    @reservation = Reservation.new
    @reservation.owner = User.new

    assert @reservation.owner
  end

  test "it has periods" do
    @reservation = Reservation.new

    assert @reservation.periods
  end

  describe 'expiration' do

    context 'with an unsaved reservation' do

      setup do
        @reservation = FactoryGirl.build(:reservation_with_credit_card)
        @reservation.add_period(Date.today)
        @reservation.total_amount_cents = 100_00 # Set this to force the reservation to have an associated cost
        Timecop.freeze
      end

      teardown do
        Timecop.return
      end

      should 'create a delayed_job task to run in 24 hours time when saved' do
        lambda {
          @reservation.save!
        }.should change(Delayed::Job, :count).by(1)

        assert Delayed::Job.first.run_at == 24.hours.from_now
      end

    end

    context 'with a confirmed reservation' do

      setup do
        @reservation = FactoryGirl.build(:reservation_with_credit_card)
        @reservation.add_period(Date.today)
        @reservation.total_amount_cents = 100_00 # Set this to force the reservation to have an associated cost
        @reservation.save!
        @reservation.confirm
      end

      should 'not send any email if the expire method is called' do
        ReservationObserver.any_instance.expects(:after_expires).never
        assert_raises @reservation.expire
      end

    end

  end

  context "confirmation" do
    should "attempt to charge user card if paying by credit card" do
      reservation = FactoryGirl.build(:reservation_with_credit_card)
      reservation.add_period(Date.today)
      reservation.total_amount_cents = 100_00 # Set this to force the reservation to have an associated cost
      reservation.save!

      reservation.owner.billing_gateway.expects(:charge)
      reservation.confirm
      assert reservation.reload.paid?
    end
  end

  context "with serialization" do
    should "work even if the total amount is nil" do
      reservation = Reservation.new
      reservation.listing = FactoryGirl.create(:listing)
      reservation.total_amount_cents = nil

      expected = { :reservation =>
        {
          :id         => nil,
          :user_id    => nil,
          :listing_id => reservation.listing.id,
          :state      => "pending",
          :cancelable => true,
          :total_cost => { :amount=>0.0, :label=>"$0.00", :currency_code=> "USD" },
          :times      => []
        }
      }

      assert_equal expected, ReservationSerializer.new(reservation).as_json
    end
  end

  context "with reservation pricing" do
    context "and a listing with some availability" do
      setup do
        @listing = FactoryGirl.create(:listing, quantity: 10)
        @user    = FactoryGirl.create(:user)
      end

      should "set total cost after creating a new reservation" do
        dates              = [Date.today, Date.tomorrow, Date.today + 5, Date.today + 6].map { |d|
          d += 1 if d.wday == 6
          d += 1 if d.wday == 0
          d
        }
        quantity           =  5
        assert reservation = @listing.reserve!(@user, dates, quantity)

        assert_equal Reservation::PriceCalculator.new(reservation).price.cents, reservation.total_amount_cents
      end

      should "not reset total cost when saving an existing reservation" do
        dates              = [1.week.from_now.monday]
        quantity           =  2
        assert reservation = @listing.reserve!(@user, dates, quantity)

        assert_not_nil reservation.total_amount_cents

        assert_no_difference "reservation.total_amount_cents" do
          reservation.confirmation_email = "joe@cuppa.com"
          reservation.save
        end

      end

      should "raise an exception if we try to reserve more desks than are available" do
        dates    = [Date.today]
        quantity = 11

        assert quantity > @listing.availability_for(dates.first)

        assert_raises DNM::PropertyUnavailableOnDate do
          @listing.reserve!(@user, dates, quantity)
        end
      end

    end
  end
end
