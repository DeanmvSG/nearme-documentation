class AddScopeToFriendlyIdSlugs < ActiveRecord::Migration
  def change
    add_column   :friendly_id_slugs, :scope, :string
    add_index    :friendly_id_slugs, [:slug, :sluggable_type]
    add_index    :friendly_id_slugs, [:slug, :sluggable_type, :scope], unique: true
  end
end