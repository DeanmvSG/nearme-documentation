class WishListItem < ActiveRecord::Base
  auto_set_platform_context
  scoped_to_platform_context

  PERMITTED_CLASSES = %w(Spree::Product Location)

  class NotPermitted < Exception
  end

  belongs_to :wishlistable, polymorphic: true

  belongs_to :wish_list
  has_one :user, through: :wish_list

  scope :by_date, -> { order 'created_at DESC' }

  after_create :increment_counters
  after_destroy :decrement_counters

  private

  def increment_counters
    wishlistable.class.increment_counter 'wish_list_items_count', wishlistable_id
  end

  def decrement_counters
    wishlistable.class.decrement_counter 'wish_list_items_count', wishlistable_id
  end
end
