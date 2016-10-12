class OrderDecorator < Draper::Decorator
  include MoneyRails::ActionViewExtension
  include Draper::LazyHelpers

  delegate_all

  delegate :current_page, :per_page, :offset, :total_entries, :total_pages

  def purchase?
    object.class == Purchase
  end

  def shipping_address_required?
    with_delivery?
  end

  def billing_address_required?
    with_delivery?
  end

  delegate :location, to: :transactable

  def user_message_recipient(current_user)
    current_user == owner ? creator : owner
  end

  #===============================

  def payment_decorator
    (payment || build_payment(shared_payment_attributes)).decorate
  end

  def payment_subscription_decorator
    (payment_subscription || build_payment_subscription(shared_payment_subscription_attributes)).decorate
  end

  def my_order_status_info
    status_info('Pending payment')
  end

  def status
    state = case object.state
            when 'canceled'
              'Canceled'
            when 'confirm'
              'Confirmed'
            when 'complete'
              'Completed'
            when 'resumed'
              'Completed'
            else
              'N/A'
            end

    state = 'Shipped' if object.shipped?

    state
  end

  def estimated_delivery
    # TODO: fix with shipping
    return 'Soon'
    result = 'N/A'

    object.shipments.each do |shipment|
      next unless shipment.state == 'shipped'
      next if shipment.shipping_method.processing_time.blank?

      processing_time = shipment.shipping_method.processing_time.to_i
      next unless processing_time > 0
      date = (shipment.shipped_at + processing_time.days).to_date
      result = I18n.l(date, format: :long)
      break
    end

    result
  end

  def company_name
    content_tag :strong, object.company.try(:name)
  end

  def shipping_address
    object.shipping_address.nil? ? fill_address_from_user(OrderAddress.new, false) : object.shipping_address
  end

  def payment_documents
    if object.payment_documents.blank?
      transactables.each do |transactable|
        transactable.document_requirements.select(&:should_show_file?).each_with_index do |doc, _index|
          object.payment_documents.build(
            user: @user,
            attachable: self,
            payment_document_info_attributes: {
              attachment_id: id,
              document_requirement_id: doc.id
            }
          )
        end
      end
    end
    object.payment_documents
  end

  def shipments
    if object.transactable && object.transactable.possible_delivery?
      object.shipments.blank? ? object.shipments.build : object.shipments
    end
    object.shipments
  end

  def payment_state
    payment.state.try(:capitalize)
  end

  def payment
    object.payment.nil? ? object.build_payment(object.shared_payment_attributes) : object.payment
  end

  def billing_address
    object.billing_address.nil? ? fill_address_from_user(OrderAddress.new, true) : object.billing_address
  end

  def save_billing_address
  end

  def display_total
    render_money(object.total_amount)
  end

  def total_units_text
    unit = 'reservations.item'
    quantity = object.transactable_line_items.sum(:quantity)
    [quantity.to_i, I18n.t(unit, count: quantity)].join(' ')
  end

  def display_shipping_address
    return '' if object.shipping_address.blank?
    shipping_address = []
    shipping_address << "#{object.shipping_address.street1}, #{object.shipping_address.city}"
    shipping_address << "#{object.shipping_address.state.name}, #{object.shipping_address.country.try(:iso).presence || object.shipping_address.country.try(:name)}, #{object.shipping_address.zip}"
    shipping_address.join('<br/>').html_safe
  end

  def reviewable?(current_user)
    current_user != company.creator && approved_at.present? && paid? && shipped?
  end

  private

  def status_info(text)
    if completed?
      "<i class='ico-check'></i>".html_safe
    else
      tooltip(text, "<span class='tooltip-spacer'>i</span>".html_safe, { class: 'ico-pending' }, nil)
    end
  end

  def fill_address_from_user(address, billing_address = true)
    address_info = billing_address ? user.billing_addresses.last : user.shipping_addresses.last

    address.attributes = address_info.dup.attributes if address_info
    address.firstname ||= user.first_name
    address.lastname ||= user.last_name
    address.phone ||= user.phone.to_s
    if user.country && !address.phone.include?('+')
      address.phone ||= "+#{user.country.calling_code} #{address.phone}"
    end

    address
  end
end
