require 'test_helper'

class Reservation::ContiguousBlockFinderTest < ActiveSupport::TestCase

  setup do
    @reservation = Reservation.new(quantity: 1)

    @transactable = stub()
    @transactable.stubs(:open_on?).returns(true)
    @transactable.stubs(:availability_for).returns(10)
    @reservation.stubs(:transactable).returns(@transactable)

    @contiguous_block_finder = Reservation::ContiguousBlockFinder.new(@reservation)
  end

  context '#contiguous_blocks' do
    should "be correct for a single date" do
      dates = date_groups_of(1, 1)
      seed_reservation_dates(dates)

      assert_equal dates, @contiguous_block_finder.contiguous_blocks
    end

    should "be correct for a set of single dates" do
      dates = date_groups_of(1, 3)
      seed_reservation_dates(dates)

      assert_equal dates, @contiguous_block_finder.contiguous_blocks
    end

    should "be correct for multiple dates" do
      dates = date_groups_of(3, 1)
      seed_reservation_dates(dates)

      assert_equal dates, @contiguous_block_finder.contiguous_blocks
    end

    should "be correct for a set of multiple dates" do
      dates = date_groups_of(3, 3)
      seed_reservation_dates(dates)

      assert_equal dates, @contiguous_block_finder.contiguous_blocks
    end

    context "semantics with availability" do
      setup do
        @reservation.quantity = 2

        # We set up a set of dates with gaps that are deemed "contiguous" by our
        # custom definition.
        @dates = [Time.zone.today, Time.zone.today + 2.days, Time.zone.today + 4.days, Time.zone.today + 5.days, Time.zone.today + 8.days]
        @dates.each do |date|
          @transactable.stubs(:availability_for).with(date).returns(2)
          @transactable.stubs(:open_on?).with(date).returns(true)
        end

        @closed = [Time.zone.today + 1.day]
        @closed.each do |date|
          @transactable.stubs(:open_on?).with(date).returns(false)
        end

        @unavailable = [Time.zone.today + 3.days]
        @unavailable.each do |date|
          @transactable.stubs(:open_on?).with(date).returns(true)
          @transactable.stubs(:availability_for).with(date).returns(1)
        end

        @transactable.stubs(:open_on?).with(Time.zone.today + 5.days).returns(false)

        seed_reservation_dates(@dates)
      end

      should "take into account listing availability" do
        blocks = @contiguous_block_finder.contiguous_blocks
        assert_equal @dates.slice(0, 4), blocks[0], blocks.inspect
        assert_equal @dates.slice(4, 1), blocks[1], blocks.inspect
      end

    end
  end

  private

  # Return dates in groups to use for seeding the tests
  def date_groups_of(count = 1, quantity = 3)
    quantity.times.map do |i|
      count.times.map do |c|
        Time.zone.today.advance(:months => i*count, :days => c)
      end
    end
  end

  def seed_reservation_dates(dates, reservation = @reservation)
    dates.flatten.uniq.each do |date|
      reservation.periods.build(:date => date)
    end
  end

end

