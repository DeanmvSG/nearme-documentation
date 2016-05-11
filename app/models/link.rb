class Link < ActiveRecord::Base
  acts_as_paranoid
  auto_set_platform_context
  scoped_to_platform_context

  belongs_to :linkable, polymorphic: true

  validates_url :url, { no_local: true, schemes: %w(http https) }
  validate :text_or_image_present

  mount_uploader :image, LinkImageUploader

  after_commit :user_added_links_to_project_event, on: [:create, :update]
  def user_added_links_to_project_event
    if linkable.present? && linkable_type == "Project" && !linkable.draft?
      event = :user_added_links_to_project
      ActivityFeedService.create_event(event, self.linkable, [self.linkable.creator], self.linkable)
    end
  end

  protected

  def text_or_image_present
    if self.text.blank? && self.image.blank?
      self.errors.add(:text, :blank)
      self.errors.add(:image, :blank)
    end
  end

end

