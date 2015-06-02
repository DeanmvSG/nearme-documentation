class CategoriesCategorizable < ActiveRecord::Base
  scoped_to_platform_context
  auto_set_platform_context

  belongs_to :category
  belongs_to :categorizable, polymorphic: true

end