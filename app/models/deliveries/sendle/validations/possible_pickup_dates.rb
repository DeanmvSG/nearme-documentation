require 'holidays'

module Deliveries
  class Sendle
    module Validations
      class PossiblePickupDates
        TIME_REQUIRED_FOR_DELIVERY = 25.hours

        def initialize(to:, from: Date.today, time_zone:)
          @to = to
          @from = from
          @time_zone = time_zone
        end

        def any?
          possible_dates.any?
        end

        def possible_dates
          range.reject do |day|
            business_day?(day) || cannot_pickup(day) || holiday?(day)
          end
        end

        def cannot_pickup(day)
          day.to_time - current_time_at_sender < TIME_REQUIRED_FOR_DELIVERY
        end

        def current_time_at_sender
          @time_zone.now
        end

        def holiday?(date)
          Holidays.on(date, country_list).any?
        end

        def country_list
          :au
        end

        def range
          Range.new @from, @to.advance(days: -1)
        end

        def business_day?(day)
          day.sunday? || day.saturday?
        end
      end
    end
  end
end