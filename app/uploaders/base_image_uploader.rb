class BaseImageUploader < BaseUploader

  process :auto_orient

  def auto_orient
    manipulate! do |img|
      img.auto_orient
      img
    end
  end
  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg png gif ico)
  end

  # Offers a placeholder while image is not uploaded yet
  def default_url
    Placeholder.new(height: 100, width: 100).path
  end
end
