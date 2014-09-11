class DatePresenter
  include ActionView::Helpers::TextHelper

  attr_accessor :dates

  def initialize(dates)
    @dates = dates.sort
  end

  def selected_dates_summary_no_html
    items = dates_in_groups.map do |block|
      if block.size == 1
        period_to_string(block.first)
      else
        period_to_string(block.first) + " - " + period_to_string(block.last)
      end
    end
    items.join(';')
  end

  def selected_dates_summary(options = {})
    wrapper = options[:wrapper].presence || :p
    separator = options[:separator].presence || :br
    separator = separator.is_a?(Symbol) ? tag(separator) : separator

    items = dates_in_groups.map do |block|
      content = if block.size == 1
                  period_to_string(block.first)
                else
                  period_to_string(block.first) + " &ndash; " + period_to_string(block.last)
                end
      content_tag(wrapper, content.html_safe)
    end
    items.join(separator).html_safe
  end

  def dates_in_groups
    dates.inject([]) { |groups, datetime|
      date = datetime.to_date
      if groups.last && ((groups.last.last+1.day) == date)
        groups.last << date
      else
        groups << [date]
      end
      groups
    }
  end

  def period_to_string(date)
    date.strftime('%A, %B %-e')
  end

  def days_in_words
    I18n.t('day', count: days).titleize
  end

  def days
    @dates_count ||= dates.count
  end

end

