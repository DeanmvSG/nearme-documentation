class OrderDrop < BaseDrop
  include CurrencyHelper

  attr_reader :order

  # id
  #   numeric identifier for this order
  # user
  #   user object representing the user who has placed this order
  # company
  #   company object to which the ordering user belongs
  # number
  #   string representing the unique identifier for this order
  # line_items
  #   an array of line items that belong to this order in the form of LineItem objects
  delegate :id, :user, :company, :number, :line_items, :line_item_adjustments,
    :shipping_profile, :adjustment, :can_host_cancel?, :can_confirm?, :can_reject?,
    :paid?, :unconfirmed?, :confirmed?, :manual_payment?, :can_complete_checkout?,
    :can_approve_or_decline_checkout?, :has_to_update_credit_card?, :user_messages,
    :archived_at, :state, :cancelable?, :archived?, :penalty_charge_apply?, :rejection_reason,
    :cancellation_policy_hours_for_cancellation, :cancellation_policy_penalty_hours,
    :created_at, :payment, :total_units_text, :enquirer_cancelable, :enquirer_editable,
    :transactable, :cancelled_at, :confirmed_at, :recurring_booking_periods, :creator, to: :order

  def initialize(order)
    @order = order.decorate
  end

  def manual_payment?
    @order.payment.try(:manual_payment?)
  end

  # the guest part of the service fee for this particular order
  def service_fee_amount_guest
    @order.service_fee_amount_guest.to_s
  end

  # the total amount to be charged for this order
  def total_amount
    @order.total_amount.to_s
  end

  # whether or not the order has products with seller attachments
  def has_seller_attachments?
    @order.transactable_line_items.each do |line_item|
      return true if line_item.line_item_source.attachments.exists?
    end

    false
  end

  def possible_payout_not_configured?
    @order.company.possible_payout_not_configured?(@order.payment.payment_gateway)
  end

  def show_not_verified_host_alert?
    PlatformContext.current.instance.click_to_call? && @order.transactable.present? && @order.user.communication.try(:verified) && !@context['current_user'].try(:communication).try(:verified)
  end

  def show_not_verified_user_alert?
    PlatformContext.current.instance.click_to_call? && @order.transactable && @order.transactable.administrator.communication.try(:verified) && !@context['current_user'].communication.try(:verified)
  end

  def payment_state
    @order.payment.try(:state).try(:humanize).try(:capitalize)
  end

  def translated_payment_method
    I18n.t("dashboard.host_reservations.payment_methods." + (@order.payment.try(:payment_method).try(:payment_method_type) || 'pending').to_s)
  end

  def outbound_shipment
    @order.shipments.outbound.first
  end

  def inbound_shipment
    @order.shipments.inbound.first
  end

  def time_to_expiration
    @order.time_to_expiry(@order.expires_at)
  end

  def payment_documents
    @order.payment_documents.select(&:persisted?)
  end

  def formatted_penalty_fee
    humanized_money_with_cents_and_symbol(@order.penalty_fee)
  end

  def all_other_orders
    @order.user.transactable_line_items.where(line_item_source_id: @order.transactable.id).map(&:line_itemable)
  end

  def new_order_item_path
    routes.new_dashboard_order_order_item_path(@order)
  end

  def new_payment_url
    routes.new_dashboard_company_orders_received_payment_path(order)
  end

  def offer_cancel_url
    routes.cancel_dashboard_company_orders_received_path(order)
  end

  def rejection_form_path
    routes.rejection_form_dashboard_company_orders_received_path(order)
  end

  def confirmation_form_path
    if @order.transactable.action_free_booking?
      routes.new_dashboard_company_orders_received_payment_path(order)
    else
      routes.new_dashboard_company_orders_received_payment_subscription_path(order)
    end
  end

  def confirm_path
    routes.confirm_dashboard_company_orders_received_path(order)
  end

  def complete_path
    routes.complete_dashboard_company_orders_received_path(order)
  end

  def offer_enquirer_cancel_path
    routes.cancel_dashboard_orders_path(order)
  end

  def included_tax?
    @first_line_item =
      first_line_item.included_tax_total_rate.zero? == false
  end

  def additional_tax?
    first_line_item.additional_tax_total_rate.zero? == false
  end

  def transactable_user_messages
    transactable.user_messages.where("author_id = :user_id OR thread_recipient_id = :user_id", user_id: @order.user_id)
  end

  private

  def first_line_item
    @first_line_item ||= @order.line_items.first || OpenStruct.new(included_tax_total_rate: 0, additional_tax_total_rate: 0)
    @first_line_item
  end

end
