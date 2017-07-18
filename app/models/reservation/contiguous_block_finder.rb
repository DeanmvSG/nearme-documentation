class Reservation::ContiguousBlockFinder
  def initialize(reservation)
    @reservation = reservation
  end

  # Return an array where each element is an array of contiguous booked
  # days
  def contiguous_blocks
    dates = @reservation.periods.map(&:date).sort

    # Hash of block start date to array of dates in the contiguous
    # block
    blocks = Hash.new { |hash, key| hash[key] = [] }

    current_start = nil
    previous_date = nil
    dates.each do |date|
      if !previous_date || !contiguous?(previous_date, date)
        current_start = date
      end

      blocks[current_start] << date
      previous_date = date
    end

    blocks.values
  end

  def real_contiguous_blocks
    dates = @reservation.periods.map(&:date).sort

    @dates ||= dates.inject([]) do |groups, datetime|
      date = datetime.to_date
      if groups.last && ((groups.last.last + 1.day) == date)
        groups.last << date
      else
        groups << [date]
      end
      groups
    end
  end

  private

  def transactable
    @reservation.transactable
  end

  # Are to dates deemed "contiguous" by our custom definition?
  # That is, are they separated only by dates that are not bookable
  # due to availability rules.
  def contiguous?(from, to)
    return false if to < from

    while from < to
      from = from.advance(days: 1)

      # Break if we reach a bookable date
      break if transactable.open_on?(from) && transactable.availability_for(from) >= @reservation.quantity
    end

    from == to
  end
end