# encoding: utf-8
class CkeditorPictureUploader < BaseCkeditorUploader
  include CarrierWave::MiniMagick
  include CarrierWave::DynamicPhotoUploads

  process :read_dimensions

  self.dimensions = {
    thumb: { width: 118, height: 100, transform: :resize_to_fill },
    content: { width: 800, height: 800, transform: :resize_to_limit }
  }

  version :thumb, from_version: :optimized do
    process dynamic_version: :thumb
  end

  version :content, from_version: :optimized do
    process dynamic_version: :content
  end

  def extension_white_list
    Ckeditor.image_file_types
  end
end
