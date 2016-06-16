class Photo < ActiveRecord::Base

  has_paper_trail
  acts_as_paranoid
  auto_set_platform_context
  scoped_to_platform_context

  # skip_activity_feed_event is used to prevent creating a new event
  # on recreate_versions
  attr_accessor :force_regenerate_versions, :skip_activity_feed_event

  include RankedModel
  has_metadata :without_db_column => true

  ranks :position, with_same: [:owner_id, :owner_type, :creator_id]

  belongs_to :owner, -> { with_deleted }, polymorphic: true, touch: true
  belongs_to :creator, -> { with_deleted }, class_name: "User"
  belongs_to :instance

  default_scope -> { rank(:position) }

  validates :image, :presence => true,  :if => lambda { |p| !p.image_original_url.present? }

  validates_length_of :caption, :maximum => 120, :allow_blank => true

  mount_uploader :image, PhotoUploader

  # Don't delete the photo from s3
  skip_callback :commit, :after, :remove_image!

  def listing
    owner_type == 'Transactable' ? owner : nil
  end

  def listing=(object)
    self.owner = object
  end

  after_commit :user_added_photos_to_project_event, on: [:create, :update]
  after_commit :user_added_photos_to_group_event, on: [:create, :update]
  def user_added_photos_to_project_event
    if owner_type == "Project" && owner.present? && !owner.draft? && !self.skip_activity_feed_event
      event = :user_added_photos_to_project
      ActivityFeedService.create_event(event, self.owner, [self.owner.creator], self) unless ActivityFeedEvent.where(followed: owner, event_source: self, event: event, created_at: Time.now-1.minute..Time.now).count > 0
    end
  end

  def user_added_photos_to_group_event
    if owner_type == "Group" && owner.present?
      event = :user_added_photos_to_group
      ActivityFeedService.create_event(event, self.owner, [self.owner.creator], self) unless ActivityFeedEvent.where(followed: owner, event_source: self, event: event, created_at: Time.now-1.minute..Time.now).count > 0
    end
  end

  def image_original_url=(value)
    super
    self.remote_image_url = value
  end

  def original_image_url
    self.image_url(:original)
  end

  def self.xml_attributes
    self.csv_fields.keys
  end

  def self.csv_fields
    { :image_original_url => 'Photo URL' }
  end

end
