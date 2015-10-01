# encoding: utf-8
class TopicCoverImageUploader < BaseUploader
  # note that we cannot change BaseUploader to BaseImageUploader
  # because of validation - cover images downloaded from social providers like
  # linkedin do not have extension
  include CarrierWave::TransformableImage

  cattr_reader :delayed_versions

  after :remove, :clean_model

  process :auto_orient


  self.dimensions = {
    medium: { width: 575, height: 196 },
    big: { width: 575, height: 441 },
  }

  version :big do
    process resize_to_fill: [dimensions[:big][:width], dimensions[:big][:height]]
  end

  version :medium do
    process resize_to_fill: [dimensions[:medium][:width], dimensions[:medium][:height]]
  end

  ASPECT_RATIO = 6.7368421053

  def auto_orient
    manipulate! do |img|
      img.auto_orient
      img
    end
  end

  def clean_model
  end

end

