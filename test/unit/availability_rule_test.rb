require 'test_helper'

class AvailabilityRuleTest < ActiveSupport::TestCase
  context "#open_at?" do
    setup do
      @availability_rule = AvailabilityRule.new(:open_hour => 6, :open_minute => 15, :close_hour => 17, :close_minute => 15)
    end

    should "return true during times of opening" do
      assert @availability_rule.open_at?(6, 15)
      assert @availability_rule.open_at?(6, 50)
      assert @availability_rule.open_at?(12, 0)
      assert @availability_rule.open_at?(17, 15), "AvailabilityRule must be opened at the time of closing"
    end

    should "return false during times closed" do
      assert !@availability_rule.open_at?(5, 0)
      assert !@availability_rule.open_at?(6, 14)
      assert !@availability_rule.open_at?(17, 16)
      assert !@availability_rule.open_at?(20, 0)
    end

  end

  context "open/close time in (H)H:MM format" do

    setup do
      @availability_rule = AvailabilityRule.new(:open_hour => 6, :open_minute => 0, :close_hour => 17, :close_minute => 0)
    end

    should 'return open time in expected format' do
      assert_equal "6:00", @availability_rule.open_time
    end

    should 'return close time in expected format' do
      assert_equal "17:00", @availability_rule.close_time
    end

  end

  context "floor_total_opening_time_in_hours" do

    should 'return floor how many hours during the day the status is "open"' do
      @availability_rule = AvailabilityRule.new(:open_hour => 9, :open_minute => 0, :close_hour => 17, :close_minute => 45)
      assert_equal 8, @availability_rule.floor_total_opening_time_in_hours
    end

    should 'return total opening time in hours distinguishing between AM and PM' do
      @availability_rule = AvailabilityRule.new(:open_hour => 0, :open_minute => 0, :close_hour => 23, :close_minute => 45)
      assert_equal 23, @availability_rule.floor_total_opening_time_in_hours
    end

    should 'return 0 when is opened for less than 1 hour' do
      @availability_rule = AvailabilityRule.new(:open_hour => 0, :open_minute => 0, :close_hour => 0, :close_minute => 45)
      assert_equal 0, @availability_rule.floor_total_opening_time_in_hours
    end

  end

  context 'validation' do

    should 'not be valid if close hour happens before open hour' do
      @availability_rule = AvailabilityRule.new(:day => 1, :open_hour => 17, :open_minute => 0, :close_hour => 9, :close_minute => 0)
      assert !@availability_rule.valid?
    end

    should 'not be valid if not opened for at least 1 hour' do
      @availability_rule = AvailabilityRule.new(:day => 1, :open_hour => 0, :open_minute => 0, :close_hour => 0, :close_minute => 45)
      assert !@availability_rule.valid?
    end

    should 'be valid if opened for at least 1 hour' do
      @availability_rule = AvailabilityRule.new(:day => 1, :open_hour => 0, :open_minute => 0, :close_hour => 1, :close_minute => 0)
      assert @availability_rule.valid?
    end
  end


  context "templates" do
    setup do
      @object = Location.new
    end

    context "applying" do
      should "clear previous availability rules" do
        rule = AvailabilityRule.new(:day => 6, :open_hour => 20, :open_minute => 0, :close_hour => 23, :close_minute => 59)
        @object.availability_rules << rule
        assert @object.availability.open_on?(:day => 6, :hour => 22)

        @object.availability_template_id = AvailabilityTemplate.first.id
        assert rule.marked_for_destruction?
        assert !@object.availability.open_on?(:day => 6, :hour => 22)
      end
    end

    context "M-F9-5" do
      setup do
        @object.availability_template_id = AvailabilityTemplate.first.id
      end

      should "have correct availability" do
        1.upto(5) do |i|
          assert !@object.availability.open_on?(:day => i, :hour => 8, :minute => 59)
          assert @object.availability.open_on?(:day => i, :hour => 9)
          assert @object.availability.open_on?(:day => i, :hour => 17)
          assert !@object.availability.open_on?(:day => i, :hour => 17, :minute => 1)
        end
        assert !@object.availability.open_on?(:day => 6, :hour => 9)
        assert !@object.availability.open_on?(:day => 0, :hour => 9)
        assert_equal AvailabilityTemplate.first.id, @object.availability_template_id
      end
    end

  end
end
