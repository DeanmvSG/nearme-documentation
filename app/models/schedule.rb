class Schedule < ActiveRecord::Base
  has_paper_trail
  acts_as_paranoid
  auto_set_platform_context
  scoped_to_platform_context

  belongs_to :instance
  belongs_to :scheduable, polymorphic: true

  has_many :schedule_exception_rules

  before_save :create_schedule_from_simple_settings, if: :use_simple_schedule

  validates_presence_of :sr_start_datetime, :sr_from_hour, :sr_to_hour, :sr_days_of_week, if: :use_simple_schedule
  validates_numericality_of :sr_every_hours, greater_than_or_equal_to: 0, allow_nil: true , if: :use_simple_schedule

  accepts_nested_attributes_for :schedule_exception_rules, allow_destroy: true

  after_validation  do
    self.sr_days_of_week = self.sr_days_of_week.reject(&:blank?).map(&:to_i)
  end


  def schedule
    @schedule ||= IceCube::Schedule === super ? super :  IceCube::Schedule.from_hash(JSON.parse(super || '{}'))
  end

  def create_schedule_from_simple_settings
    @schedule = IceCube::Schedule.new(sr_start_datetime)
    rule = IceCube::Rule.weekly.day(sr_days_of_week)
    if sr_every_hours.to_i > 0
      step = sr_every_hours
      hour = sr_start_datetime.hour
      hours = []
      # add all hours after first event
      loop do
        hours << hour
        hour += step
        break if hour > sr_to_hour.hour + sr_from_hour.min.to_f / 60
      end
      # add all hours before the first event
      hour = sr_start_datetime.hour - step
      loop do
        hours << hour
        hour -= step
        break if hour < sr_to_hour.hour + sr_from_hour.min.to_f / 60
      end
      rule.hour_of_day(hours.sort)
    end
    schedule.add_recurrence_rule rule
    self.schedule = @schedule.to_hash.to_json
  end

  def days_of_week_selected
    if self.sr_days_of_week.reject(&:blank?).blank?
      self.errors.add(:sr_days_of_week, :blank)
    end
  end

end

