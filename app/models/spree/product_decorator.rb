Spree::Product.class_eval do
  include Spree::Scoper
  include Impressionable

  has_many :line_items, through: :variants
  has_many :orders, through: :line_items

  belongs_to :instance
  belongs_to :user
  belongs_to :administrator, class_name: 'User'
  has_many :user_messages, as: :thread_context, inverse_of: :thread_context

  scope :approved, -> { where(approved: true) }
  scope :currently_available, -> { where("(#{Spree::Product.quoted_table_name}.available_on <= ? OR #{Spree::Product.quoted_table_name}.available_on IS NULL)", Time.zone.now) }
  scope :searchable, -> { approved.currently_available }

  _validators.reject!{ |key, _| key == :slug }

  _validate_callbacks.reject! do |callback|
    callback.raw_filter.attributes.delete :slug if callback.raw_filter.is_a?(ActiveModel::Validations::PresenceValidator)
  end

  validates :slug, uniqueness: { scope: [:instance_id, :company_id, :partner_id, :user_id] }

  # TODO: in Phase 2
  #after_initialize :apply_transactable_type_settings

  store_accessor :status, [:current_status]

  def cross_sell_products
    cross_sell_skus.map do |variant_sku|
      Spree::Variant.where(sku: variant_sku).first.try(:product)
    end.compact
  end

  def to_liquid
    Spree::ProductDrop.new(self)
  end

  def administrator
    super.presence || user
  end
end
