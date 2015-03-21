Spree::Image.class_eval do
  include Spree::Scoper
  include RankedModel

  mount_uploader :image, SpreePhotoUploader

  # Don't delete the photo from s3
  skip_callback :commit, :after, :remove_image!

  ranks :position, with_same: [:viewable_id, :viewable_type]
  default_scope -> { rank(:position) }

  _validators.reject!{ |key, _| [:attachment].include?(key) }
  _validate_callbacks.each do |callback|
    callback.raw_filter.attributes.delete :attachment if callback.raw_filter.is_a?(Paperclip::Validators::AttachmentPresenceValidator)
  end

  def image_original_url=(value)
    super
    self.remote_image_url = value
  end

  def self.csv_fields
    { image_original_url: 'Image URL' }
  end
end
