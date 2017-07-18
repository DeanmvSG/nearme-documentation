# frozen_string_literal: true
class OverbookingValidator
  def initialize(order, form = nil)
    @order = order
    @form = form
    @error_object = (@form || @order)
  end

  def validate
    @conflicting_orders = @order.conflicting_orders
    check_quantity
    check_all_days_are_open

    return unless @conflicting_orders.any?

    @error_object.errors.add(
      :base,
      I18n.t('reservations_review.errors.dates_not_available', dates: get_invalid_dates.join(', '))
    )
  end

  private

  def check_all_days_are_open
    unavailable_dates = @order.periods.reject(&:transactable_open_on?)
    return unless unavailable_dates.present?

    @error_object.errors.add(
      :base,
      I18n.t('reservations_review.errors.dates_closed', dates: unavailable_dates.map(&:date).join(', '))
    )
  end

  def check_quantity
    return if @order.quantity <= @order.transactable.quantity
    @error_object.errors.add(
      :base,
      I18n.t('reservations_review.errors.quantity_not_available')
    )
  end

  def get_invalid_dates
    if @order.is_recurring?
      @conflicting_orders.map(&:periods).flatten.map(&:as_formatted_string)
    else
      @order.periods.map(&:as_formatted_string) &
        @conflicting_orders.map(&:periods).flatten.map(&:as_formatted_string)
    end
  end
end