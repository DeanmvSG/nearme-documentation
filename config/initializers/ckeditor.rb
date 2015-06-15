Ckeditor.setup do |config|
  require 'ckeditor/orm/active_record'
  config.asset_path = '/assets/ckeditor/'
  config.assets_languages = %w(en)
  config.attachment_file_types = %w(doc docx xls odt ods pdf rar zip tar tar.gz swf mp4 css txt text js)
  config.image_file_types = %w(jpg jpeg png gif tiff)
end
