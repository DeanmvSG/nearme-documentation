class DimensionsTemplateDrop < BaseDrop
  # package name and description
  def label
    format('%s (%s)', source.name, source.description)
  end
end