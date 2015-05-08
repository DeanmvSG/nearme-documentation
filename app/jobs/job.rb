# Base class for our Jobs.
#
# This encapsulates 'job' units of work and any background execution semantics,
# that they may or may not have.
#
# Usage:
#
#   Define a Job:
#
#   class MyJob < Job
#     def after_initialize(arg1, arg2)
#       @arg1 = arg1
#       @arg2 = arg2
#     end
#
#     def perform
#       # Execute the Job
#     end
#   end
#
#   Using a Job throughout the application:
#
#   MyJob.perform(arg1, arg2)
#
#   Note:
#     * PlatformContext will be automatically inserted, that's why make sure you use after_initialize and not initialize in custom job class
#     * Other application code is only concerned that the responsibility for
#       certain logic is handled by the Job.
#     * That is, it is not concerned that the Job executes asynchronously, or
#       how it does that.
class Job

  def initialize(platform_context_detail_class, platform_context_detail_id, *args)
    @platform_context_detail_class = platform_context_detail_class.try(:constantize)
    @platform_context_detail_id = platform_context_detail_id
    after_initialize(*args)
  end

  def before(job)
    @platform_context = PlatformContext.current = begin
                                                    if @platform_context_detail_class.blank? || @platform_context_detail_id.blank?
                                                      nil
                                                    elsif @platform_context_detail_class.respond_to?(:with_deleted)
                                                      PlatformContext.new(@platform_context_detail_class.with_deleted.find(@platform_context_detail_id))
                                                    else
                                                      PlatformContext.new(@platform_context_detail_class.find(@platform_context_detail_id))
                                                    end
                                                  end

    Transactable.clear_custom_attributes_cache
    User.clear_custom_attributes_cache
    Spree::Product.clear_custom_attributes_cache
  end

  def after(job)
    PlatformContext.current = nil
  end

  def after_initialize(*args)
  end

  def self.perform(*args)
    if run_in_background?
      perform_async(*args)
    else
      build_new(*args).perform
    end
  end

  def self.perform_later(when_perform, *args)
    if run_in_background?
      enqueue(*args, run_at: get_performing_time(when_perform))
    else
      # invoking get_perfming_time is unnecessary, but we want to catch errors in this method in test environment
      get_performing_time(when_perform)
      build_new(*args).perform unless jobs_to_be_not_invoked_immediately.include?(self.name.to_s)
    end
  end

  def self.perform_async(*args)
    enqueue(*args, run_at: nil)
  end

  def self.build_new(*args)
    Rails.logger.warn "#{self.name} has no PlatformContext" if PlatformContext.current.blank?
    new(PlatformContext.current.try(:platform_context_detail).try(:class).try(:name), PlatformContext.current.try(:platform_context_detail).try(:id), *args)
  end

  def self.run_in_background?
    Rails.application.config.run_jobs_in_background
  end

  def self.get_performing_time(when_perform)
    performing_time = case when_perform
                      when ActiveSupport::Duration
                        Time.zone.now + when_perform
                      when Fixnum
                        Time.zone.now + when_perform
                      when ActiveSupport::TimeWithZone
                        when_perform
                      when Time
                        raise "Job.perform_later: use TimeWithZone (i.e. Time.zone.now instead of Time.now etc)"
                      else
                        raise "Job.perform_later: Unknown first argument, must be number of seconds or time with zone - was #{when_perform} (#{when_perform.class})"
                      end
    performing_time
  end

  def self.jobs_to_be_not_invoked_immediately
    ["ReservationExpiryJob", "RecurringBookingExpiryJob"]
  end

  private

  def self.enqueue(*args, run_at: nil)
    params = {
      priority:    get_priority,
      queue:       get_queue,
      instance_id: PlatformContext.current.try(:instance).try(:annotated_id)
    }
    params.merge!(run_at: run_at) if run_at.present?
    Delayed::Job.enqueue(build_new(*args), params)
  end

  def self.get_priority
    self.respond_to?(:priority) ? self.priority : 20
  end

  def self.get_queue
    self.respond_to?(:queue) ? self.queue : 'default'
  end
end
