class UserStatusUpdate < ActiveRecord::Base
  auto_set_platform_context
  scoped_to_platform_context

  belongs_to :user
  belongs_to :updateable, polymorphic: true
  has_and_belongs_to_many :topics

  validates_presence_of :text, :updateable_type, :updateable_id
  after_commit :create_activity_feed_event, on: :create
  def create_activity_feed_event
    event = "user_updated_#{self.updateable_type.to_s.downcase}_status".to_sym
    affected_objects = [self.user] + self.topics + [self.updateable]
    ActivityFeedService.create_event(event, self.user, affected_objects, self)
  end
end