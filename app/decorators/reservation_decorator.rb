class ReservationDecorator < Draper::Decorator
  include Draper::LazyHelpers
  include CurrencyHelper
  include TooltipHelper
  include FeedbackDecoratorHelper
  
  delegate_all

  delegate :days_in_words, :nights_in_words, :selected_dates_summary, :dates_in_groups, :period_to_string, to: :date_presenter

  def days
    periods.size
  end

  def hourly_summary_for_first_period(show_date = true)
    reservation_period = periods.first.decorate
    reservation_period.hourly_summary(show_date)
  end

  def subtotal_price
    if subtotal_amount.to_f.zero?
      "Free!"
    else
      humanized_money_with_cents_and_symbol(subtotal_amount)
    end
  end

  def service_fee_guest
    if service_fee_amount_guest.to_f.zero?
      "Free!"
    else
      humanized_money_with_cents_and_symbol(service_fee_guest_wo_charges)
    end
  end

  def total_price
    if total_amount.to_f.zero?
      "Free!"
    else
      humanized_money_with_cents_and_symbol(total_amount)
    end
  end

  def paid
    if free?
      humanized_money_with_cents_and_symbol(0.0)
    elsif paid?
      humanized_money_with_cents_and_symbol(successful_payment_amount)
    else
      payment_status.titleize
    end
  end

  def status_class
    if confirmed?
      'confirmed'
    elsif unconfirmed?
      'unconfirmed'
    elsif cancelled? || rejected?
      'cancelled'
    end
  end

  def status_icon
    if confirmed?
      'ico-check'
    elsif unconfirmed?
      'ico-pending'
    elsif cancelled? || rejected?
       'ico-close'
    elsif expired?
      'ico-time'
    end
  end

  def formatted_balance
    humanized_money_with_cents_and_symbol(balance/100.0)
  end

  def dates
    periods.map do |period|
      "#{period.date.strftime('%Y-%m-%d')} (#{'desk'.pluralize(quantity)})"
    end.to_sentence
  end

  def dates_to_array
    periods.map do |period|
      "#{period.date.strftime('%Y-%m-%d')}"
    end
  end

  def manage_guests_action_column_class
    buttons_count = [can_host_cancel?, can_confirm?, can_reject?].count(true)
    "split-#{buttons_count}"
  end

  def short_dates
    first = date.strftime('%-e %b')
    last = last_date.strftime('%-e %b')

    first == last ? first : "#{first} - #{last}"
  end

  def long_dates
    first = date.strftime('%-e %b, %Y')
    last = last_date.strftime('%-e %b, %Y')

    first == last ? first : "#{first} - #{last}"
  end

  def format_reservation_periods
    periods.map do |period|
      period = period.decorate
      date = period.date.strftime('%-e %b')
      if listing.hourly_reservations?
        start_time = period.start_minute_of_day_to_time.strftime("%l:%M%P").strip
        end_time = period.end_minute_of_day_to_time.strftime("%l:%M%P").strip
        ('%s %s&ndash;%s' % [date, start_time, end_time]).html_safe
      else
        date
      end
    end.join(', ')
  end

  def my_booking_status_info
    status_info("Pending confirmation from host. Booking will expire in #{time_to_expiry(expiry_time)}.")
  end

  def manage_booking_status_info
    status_info("You must confirm this booking within #{time_to_expiry(expiry_time)} or it will expire.")
  end

  def manage_booking_status_info_new
    raw("You must confirm this booking within <strong>#{time_to_expiry(expiry_time)}</strong> or it will expire.")
  end

  def user_message_recipient
    owner
  end

  def user_message_summary(user_message)
    if user_message.thread_context.present? && user_message.thread_context.listing.present? && user_message.thread_context.location
      link_to user_message.thread_context.name, location_path(user_message.thread_context.location, user_message.thread_context.listing)
    else
      "[Deleted]"
    end
  end

  def state_to_string
    return 'declined' if rejected?
    state.split('_').first
  end

  def time_to_expiry(time_of_event)
    current_time = Time.zone.now
    total_seconds = time_of_event - current_time
    hours = (total_seconds/1.hour).floor
    minutes = ((total_seconds-hours.hours)/1.minute).floor
    if hours < 1 and minutes < 1
      'less than minute'
    else
      if hours < 1
        '%d minutes' % [minutes]
      else
        '%d hours, %d minutes' % [hours, minutes]
      end
    end
  end

  def humanized_number_of_periods
    listing.overnight_booking? ? date_presenter.nights_in_words : date_presenter.days_in_words
  end

  def feedback_object
    object
  end

  private

  def status_info(text)
    if state == 'unconfirmed'
      tooltip(text, "<span class='tooltip-spacer'>i</span>".html_safe, {class: status_icon}, nil)
    else
      "<i class='#{status_icon}'></i>".html_safe
    end
  end

  def date_presenter
    @date_presenter ||= DatePresenter.new(periods.map(&:date))
  end

end
