class LineItem < ActiveRecord::Base

  include Modelable

  # line_itemable relation is polymorphic becuase we associate RecurringBookingPeriod
  # as well as Order object with it subclasses
  # NOTE that in most cases line_item.order will do the trick
  belongs_to :line_itemable, -> { with_deleted }, polymorphic: true
  belongs_to :line_item_source, -> { with_deleted }, polymorphic: true
  belongs_to :transactable_pricing, -> { with_deleted }, class_name: 'Transactable::Pricing'
  belongs_to :user, -> { with_deleted }
  belongs_to :company, -> { with_deleted }
  belongs_to :order, foreign_key: 'line_itemable_id'

  monetize :net_price_cents, with_model_currency: :currency
  monetize :gross_price_cents, with_model_currency: :currency
  monetize :unit_price_cents, with_model_currency: :currency
  monetize :total_price_cents, with_model_currency: :currency
  monetize :additional_tax_price_cents, with_model_currency: :currency
  monetize :included_tax_price_cents, with_model_currency: :currency

  delegate :currency, :owner_id, to: :line_itemable, allow_nil: true
  delegate :action, to: :transactable_pricing, allow_nil: true

  validates :quantity, :numericality => { :greater_than_or_equal_to => 1 }

  before_create :calculate_tax

  scope :except_optional, -> { where("line_items.type != 'LineItem::Optional'") }
  scope :service, -> { where(receiver: ['service', 'mpo']) }
  scope :host, -> { where(receiver: 'host') }

  scope :join_orders, -> { joins("INNER JOIN orders ON orders.id = line_items.line_itemable_id
    AND line_items.line_itemable_type IN (\'#{Order::ORDER_TYPES.join('\', \'')}\')") }
  scope :join_transactables, -> { joins('INNER JOIN transactables ON transactables.id = line_items.line_item_source_id') }

  scope :by_period, -> (start_date, end_date = Time.zone.today.end_of_day) {
    where(created_at: start_date..end_date)
  }

  # TODO make sure that for all type of orders line_items.user_id == trasnactables.creator_id
  # and switch to user_id
  scope :of_lister, -> (lister) { where('transactables.creator_id = ?', lister.id) }
  scope :of_order_owner, -> (owner) { join_orders.where('orders.user_id = ?', owner.id) }

  def cart_position
    10
  end

  def editable?
    false
  end

  def deletable?
    false
  end

  def description
  end

  def single_money
  end

  def total_price_cents
    gross_price_cents * self.quantity
  end

  def net_price_cents
    (self.unit_price_cents - self.included_tax_price_cents)
  end

  def gross_price_cents
    self.unit_price_cents + self.additional_tax_price_cents
  end

  def can_supply?(new_quantity)
    line_item_source.quantity >= new_quantity.to_i
  end


  def tax_calculator
    Reservation::TaxCalculator.new(self.line_itemable, self)
  end

  def to_liquid
    @line_item_drop ||= LineItemDrop.new(self)
  end

  def current_instance
    @current_instance ||= PlatformContext.current.instance
  end

  def buyer_type_review_receiver
    line_itemable.user
  end

  def seller_type_review_receiver
    line_item_source.creator
  end

  private

  def calculate_tax
    self.additional_tax_total_rate = tax_calculator.additional_tax_rate.value
    self.additional_tax_price_cents = 0.01 * self.additional_tax_total_rate * self.unit_price_cents

    self.included_tax_total_rate = tax_calculator.included_tax_rate.value
    self.included_tax_price_cents = (0.01 * self.included_tax_total_rate * self.unit_price_cents) / (1 + 0.01 * self.included_tax_total_rate)

    true
  end
end

