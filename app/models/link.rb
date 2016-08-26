class Link < ActiveRecord::Base
  acts_as_paranoid
  auto_set_platform_context
  scoped_to_platform_context

  # skip_activity_feed_event is used to prevent creating a new event
  # on recreate_versions
  attr_accessor :skip_activity_feed_event

  belongs_to :linkable, polymorphic: true

  validates_url :url, { no_local: true, schemes: %w(http https) }
  validate :text_or_image_present

  mount_uploader :image, LinkImageUploader

  after_commit :user_added_links_event, on: [:create, :update], if: -> { ['Group', 'Transactable'].include?(linkable_type) }

  def user_added_links_event
    if linkable.present? && !linkable.draft? && !self.skip_activity_feed_event
      event = ['user_added_links_to', linkable_type.downcase].join('_').to_sym
      ActivityFeedService.create_event(event, self.linkable, [self.linkable.creator], self)
    end
  end

  def valid_attribute?(attribute_name)
    self.valid?
    self.errors[attribute_name].blank?
  end

  protected

  def text_or_image_present
    if self.text.blank? && self.image.blank?
      self.errors.add(:text, :blank)
      self.errors.add(:image, :blank)
    end
  end

end
