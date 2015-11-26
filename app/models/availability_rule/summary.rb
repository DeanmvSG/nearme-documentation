# A summary wrapper for AvailabilityRule collections which provides an interface to the availability rules in aggregate.
class AvailabilityRule::Summary
  def initialize(rules)
    @rules = rules
  end

  # Iterate over each day in the week and yield the day of week and the availability rule (if any) for that day.
  def each_day(monday_first = true)
    days = (0..6).to_a
    days.push(days.shift) if monday_first

    days.each do |day|
      yield(day, rule_for_day(day))
    end
  end

  # Iterate over each day in the week if no rule is available for a day an new empty rule is created
  def full_week(monday_first = true)
    result = []
    each_day do |day, rule|
      result << { day: day, rule: (rule || AvailabilityRule.new(:days => [day]))}
    end
    result
  end

  # Return the availability rule (if any) for the given day of the week.
  def rule_for_day(day)
    @rules.detect { |rule| day.in? rule.days }
  end

  # Return whether or not the target is open given options
  #
  # options - The availability query
  #           :day  - The day of the week
  #           :hour - The hour of the day
  #           :minute - The minute of the day
  #           :start_minute - Start minute of the day
  #           :end_minute - End minute of the day
  def open_on?(options)
    raise ArgumentError.new("Options must be a hash") unless options.is_a?(Hash)

    day = options[:day]
    day ||= options[:date] && options[:date].wday
    raise ArgumentError.new("Must provide day of week") unless day

    rule = rule_for_day(day)
    return false unless rule

    if options[:hour]
      return false unless rule.open_at?(options[:hour], options[:minute] || 0)
    end

    if options[:start_minute]
      return false unless rule.open_at?(options[:start_minute]/60, options[:start_minute]%60)
    end

    if options[:end_minute]
      return false unless rule.open_at?(options[:end_minute]/60, options[:end_minute]%60)
    end

    true
  end

  # Returns an array of days that the listing is open for
  # Days are 0..6, where 0 is Sunday and 6 is Saturday
  def days_open
    @days_open ||= @rules.map(&:days).flatten.compact.uniq
  end

  def consecutive_days_open?
    return true if days_open.size >= 4
    days_open.sort.each_with_index do |day, i|
      return true if day + 1 == days_open[i + 1]
    end
    false
  end

  # Returns the minute of the day that the listing opens, or nil
  def open_minute_for(date)
    rule_for_day(date.wday).try(:day_open_minute)
  end

  # Returns the minute of the day that the listing closes, or nil
  def close_minute_for(date)
    rule_for_day(date.wday).try(:day_close_minute)
  end

  def earliest_open_minute
    @rules.map(&:day_open_minute).min
  end

  def latest_close_minute
    @rules.map(&:day_close_minute).max
  end

end

