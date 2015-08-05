module CategoriesHelper
  def build_categories_hash_for_object(object, root_categories)
    @object_permalinks = object.categories.pluck(:permalink)
    @root_categories = @object_permalinks.map { |p| p.split('/')[0] }.uniq
    categories = {}
    root_categories.find_each do |category|
      children = if @root_categories.include?(category.permalink)
                   category.children.map { |child| build_value_for_category(child) }.compact
                 else
                   []
                 end
      categories[category.name] = { 'name' => category.translated_name, 'children' => children }
    end
    categories
  end

  protected

  def build_value_for_category(category)
    if @object_permalinks.include?(category.permalink)
      if category.leaf?
        category.translated_name
      else
        { category.translated_name => category.children.map { |child| build_value_for_category(child) }.compact }
      end
    end
  end
end
