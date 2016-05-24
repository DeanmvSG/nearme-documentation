class ScheduleExceptionRule < ActiveRecord::Base
  has_paper_trail
  auto_set_platform_context
  scoped_to_platform_context

  belongs_to :schedule, touch: true
  belongs_to :availability_template, touch: true

  attr_accessor :user_duration_range_start, :user_duration_range_end

  [:user_duration_range_start, :user_duration_range_end].each do |method|
    define_method(method) do
      instance_variable_get(:"@#{method}").presence || send(method.to_s.sub('user_', ''))
    end
  end

  default_scope { order('created_at ASC') }

  scope :at, -> (date) { where("date(duration_range_start) <= ? AND date(duration_range_end) >= ?", date, date) }
  scope :future, -> { where("duration_range_end >= ?", Date.current) }

  def parse_user_input
    self.duration_range_start = date_time_handler.convert_to_datetime(user_duration_range_start).try(:beginning_of_day) if user_duration_range_start.present?
    self.duration_range_end = date_time_handler.convert_to_datetime(user_duration_range_end).try(:end_of_day) if user_duration_range_end.present?
    errors.add(:duration_range_end, :must_be_later) if duration_range_end.try(:<, duration_range_start) if duration_range_start.present?
    self.user_duration_range_start = duration_range_start
    self.user_duration_range_end = duration_range_end
    true
  end

  def to_liquid
    @schedule_exception_rule_drop ||= ScheduleExceptionRuleDrop.new(self)
  end

  def range
    {from: duration_range_start.to_date, to: duration_range_end.to_date}
  end

  def all_dates
    (duration_range_start.to_date..duration_range_end.to_date).map(&:to_date)
  end

  def schedulable
    availability_template || schedule
  end

  protected

  def date_time_handler
    @date_time_handler ||= DateTimeHandler.new
  end
end

