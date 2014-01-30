class Photo < ActiveRecord::Base
  has_paper_trail

  include RankedModel

  ranks :position, with_same: [:listing_id]

  attr_accessible :creator_id, :listing_id, :caption, :image, :image_versions_generated_at, :image_transformation_data, :position
  belongs_to :listing
  belongs_to :creator, class_name: "User"

  default_scope -> { rank(:position) }
  
  acts_as_paranoid

  after_create :notify_user_about_change
  after_destroy :notify_user_about_change
  after_save :update_counter
  after_destroy :update_counter

  delegate :notify_user_about_change, :to => :listing, :allow_nil => true


  validates :image, :presence => true,  :if => lambda { |p| !p.image_original_url.present? }

  validates_length_of :caption, :maximum => 120, :allow_blank => true

  extend CarrierWave::SourceProcessing
  mount_uploader :image, PhotoUploader, :use_inkfilepicker => true

  # Don't delete the photo from s3
  skip_callback :commit, :after, :remove_image!

  private
  def update_counter
    listing.update_column(:photos_count, listing.photos.count) if listing.present?
  end

end
