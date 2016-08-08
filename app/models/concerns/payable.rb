# This module standardize all "payable" objects
# For now it's included in Reservation, Purchase and RecurringBookingPeriod class

module Payable
  extend ActiveSupport::Concern

  included do

    attr_accessor :additional_charge_ids

    has_one :payment, as: :payable
    has_one :payment_subscription, as: :subscriber

    has_many :line_items, as: :line_itemable
    has_many :transactable_line_items, class_name: 'LineItem::Transactable', as: :line_itemable, dependent: :destroy
    has_many :additional_line_items, class_name: 'LineItem::Additional', as: :line_itemable, dependent: :destroy
    has_many :insurance_line_items, class_name: 'LineItem::Insurance', as: :line_itemable, dependent: :destroy
    has_many :shipping_line_items, class_name: 'LineItem::Shipping', as: :line_itemable, dependent: :destroy
    has_many :tax_line_items, class_name: 'LineItem::Tax', as: :line_itemable, dependent: :destroy
    has_many :service_fee_line_items, class_name: 'LineItem::ServiceFee', as: :line_itemable, dependent: :destroy
    has_many :host_fee_line_items, as: :line_itemable, dependent: :destroy

    accepts_nested_attributes_for :payment
    accepts_nested_attributes_for :payment_subscription
    accepts_nested_attributes_for :transactable_line_items, allow_destroy: Proc.new {|p| p.inactive? }
    accepts_nested_attributes_for :additional_line_items, allow_destroy: Proc.new {|p| p.deleteable? }

    validates_associated :line_items

    before_update :authorize_payment
    before_create :build_first_line_item
    after_save :create_additional_charges

    delegate :remote_payment?, :manual_payment?, :active_merchant_payment?, :paid?, :billing_authorizations, to: :payment, allow_nil: true


    def authorize_payment
      if (payment && payment.valid? && payment.pending? && self.valid?)
        if (skip_payment_authorization? || payment.authorize) && inactive?
          activate! unless payment.express_checkout_payment?
        end
      elsif payment_subscription && payment_subscription.valid? && payment.blank? && self.valid? && payment_subscription.credit_card.store!
        activate! if inactive?
      end
    end

    def build_first_line_item
      if line_items.blank? && transactable_line_items.blank?
        transactable_line_items.build(
          user: self.user,
          name: self.transactable.name,
          quantity: self.quantity,
          line_item_source: self.transactable,
          unit_price: price_calculator.price,
          line_itemable: self,
          service_fee_guest_percent: action.service_fee_guest_percent,
          service_fee_host_percent: action.service_fee_host_percent,
          transactable_pricing_id: self.try(:transactable_pricing_id)
        )
      end
    end

    def create_additional_charges
      return true unless respond_to?(:additional_charge_types)
      additional_charge_types.get_mandatory_and_optional_charges(additional_charge_ids).uniq.map do |act|
        self.additional_line_items.where(line_item_source: act).first_or_create(
          line_itemable: self,
          line_item_source: act,
          optional: act.optional?,
          receiver: act.commission_receiver,
          name: act.name,
          quantity: 1,
          unit_price: act.amount
        )
      end
    end

    def update_payment_attributes
      self.payment.attributes = shared_payment_attributes
    end

    def has_service_fee?
      service_fee_line_items.any? && !service_fee_amount_guest_cents.zero?
    end

    def payment_attributes=(payment_attrs={})
      super(payment_attrs.merge(shared_payment_attributes))
    end

    def payment_subscription_attributes=(payment_subscription_attrs={})
      super(payment_subscription_attrs.merge(shared_payment_subscription_attributes))
    end

    def shared_payment_attributes
      {
        payer: owner,
        company: company,
        company_id: company_id,
        currency: currency,
        total_amount_cents: total_amount_cents,
        subtotal_amount_cents: subtotal_amount_cents,
        service_fee_amount_guest_cents: service_fee_amount_guest.try(:cents) || 0,
        service_fee_amount_host_cents: service_fee_amount_host.try(:cents) || 0,
        service_additional_charges_cents: service_additional_charges.try(:cents) || 0,
        host_additional_charges_cents: host_additional_charges.try(:cents) || 0,
        cancellation_policy_hours_for_cancellation: cancellation_policy_hours_for_cancellation,
        cancellation_policy_penalty_percentage: cancellation_policy_penalty_percentage,
        payable: self
      }
    end

    def shared_payment_subscription_attributes
      {
        payer: owner,
        company: company,
        subscriber: self
      }
    end

    monetize :total_amount_cents, with_model_currency: :currency
    def total_amount_cents
      subtotal_amount_cents + service_additional_charges_cents + host_additional_charges_cents + service_fee_amount_guest_cents + shipping_total_cents + total_tax_amount_cents
    end

    # Not really needed I think
    monetize :subtotal_amount_cents
    def subtotal_amount_cents
      unit_price_cents
    end

    monetize :unit_price_cents, with_model_currency: :currency
    def unit_price_cents
      transactable_line_items.map(&:total_price_cents).sum
    end

    monetize :shipping_total_cents, with_model_currency: :currency
    def shipping_total_cents
      shipping_line_items.reload.map(&:total_price_cents).sum
    end

    monetize :total_tax_amount_cents, with_model_currency: :currency
    def total_tax_amount_cents
      tax_line_items.map(&:total_price_cents).sum
    end

    monetize :service_additional_charges_cents, with_model_currency: :currency
    def service_additional_charges_cents
      additional_line_items.service.map(&:total_price_cents).sum
    end

    monetize :host_additional_charges_cents, with_model_currency: :currency
    def host_additional_charges_cents
      additional_line_items.host.map(&:total_price_cents).sum
    end

    monetize :service_fee_amount_guest_cents, with_model_currency: :currency
    def service_fee_amount_guest_cents
      service_fee_line_items.map(&:total_price_cents).sum
    end

    monetize :service_fee_amount_host_cents, with_model_currency: :currency
    def service_fee_amount_host_cents
      host_fee_line_items.map(&:total_price_cents).sum
    end

    monetize :total_payable_to_host_cents, with_model_currency: :currency
    def total_payable_to_host_cents
      subtotal_amount_cents + host_additional_charges_cents + shipping_total_cents + total_tax_amount_cents - service_fee_amount_host_cents
    end
  end
end
