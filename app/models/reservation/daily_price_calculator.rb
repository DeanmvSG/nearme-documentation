# encoding: utf-8
#
# Object encapsulating our pricing calculation logic.
# Pass it a reservation, and let it do its thing.
#
# NB: Note that there is a corresponding JS calculation class
#     to calculate the price client-side. If logic changes,
#     be sure to update that as well.
class Reservation::DailyPriceCalculator
  attr_reader :reservation

  def initialize(reservation)
    @reservation = reservation
    @pricing = @reservation.transactable_pricing
    @contiguous_block_finder = Reservation::ContiguousBlockFinder.new(reservation)
  end

  # Returns the total price for the listing and it's chosen
  # periods. Returns nil if the selection is unbookable
  def price
    blocks = contiguous_blocks

    blocks.map do |block|
      price_for_days(@pricing.overnight_booking? && block.size > 1 ? (block.size - 1) : block.size) rescue 0.0
    end.sum.to_money
  end

  # Returns true if the selection of dates are valid in terms of the pricing
  # method. Depending on the pricing method, certain selections of dates may
  # not be bookable (i.e. 1 day is unbookable for a listing that requires
  # minimum of 5 days).
  def valid?
    listing && !contiguous_blocks.empty? && contiguous_blocks.all? do |block|
      block.length >= @pricing.action.minimum_booking_days
    end
  end

  def number_of_nights
    real_contiguous_blocks.map { |group| group.many? ? group.size - 1 : group.size }.sum
  end

  def unit_price
    @pricing.action.price_for_lowest_no_of_day
  end

  private

  # Price for contiguous days in as a Money object
  def price_for_days(days)
    prices = @pricing.try(:all_prices_for_unit)

    if prices
      # Determine the matching block size and price
      block_size = prices.keys.sort.inject do |largest_block, block_days|
        largest_block = block_days if days >= block_days
        largest_block
      end
      pricing = prices[block_size]
      price = pricing[:price]
      # Our pricing logic per block is the block price
      # plus a pro-rated cost for each additional day used.
      # Pro rate even when favourable pricing is disabled to avoid error when
      # only prices for longer period than days are enabled.
      if @reservation.favourable_pricing_rate || days < block_size
        (((days / block_size.to_f) * price.cents).round / BigDecimal.new(price.currency.subunit_to_unit)).to_money(price.currency)
      else
        priced_days = days / block_size
        left_days = days - priced_days * block_size
        calculated_price = ((priced_days * price.cents).round / BigDecimal.new(price.currency.subunit_to_unit)).to_money(price.currency)
        if left_days.zero?
          calculated_price
        else
          calculated_price + price_for_days(left_days)
        end
      end
    end
  end

  def listing
    @reservation.transactable
  end

  def contiguous_blocks
    @contiguous_block_finder.contiguous_blocks
  end

  def real_contiguous_blocks
    @contiguous_block_finder.real_contiguous_blocks
  end
end
