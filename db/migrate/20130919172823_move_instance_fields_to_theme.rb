class MoveInstanceFieldsToTheme < ActiveRecord::Migration

  class Instance < ActiveRecord::Base
    has_one :theme, :as => :owner
  end

  class Theme < ActiveRecord::Base
    belongs_to :owner, :polymorphic => true
  end

  def up
    columns = [:site_name, :description, :tagline, :support_email, :contact_email, :address, :meta_title,
               :phone_number, :support_url, :blog_url, :twitter_url, :facebook_url]
    change_table :themes do |t|
      t.string *columns
    end

    Instance.all.each do |i|
      t = i.theme
      if t
        t.owner_type = 'Instance'
        t.name = i.name unless t.name
        columns.each do |col|
          t.send("#{col}=", i.send(col))
        end
        t.save!(:validate => false)
      end
    end

    change_table :instances do |i|
      i.remove *columns
    end
  end

  def down
    columns = [:site_name, :description, :tagline, :support_email, :contact_email, :address, :meta_title,
               :phone_number, :support_url, :blog_url, :twitter_url, :facebook_url]
    change_table :instances do |t|
      t.string *columns
    end

    Instance.all.each do |i|
      t = i.theme
      if t
        columns.each do |col|
          i.send("#{col}=", t.send(col))
        end
        i.save!(:validate => false)
      end
    end
    change_table :themes do |t|
      t.remove *columns
    end
  end
end
