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
  def default_url(*args)
    version = args.shift
    dimensions = version && self.class.dimensions.has_key?(version) ? self.class.dimensions[version] : {width: 100, height: 100}
    Placeholder.new(dimensions).path
  end
end
