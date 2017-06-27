class GetRidOfDefaultInstanceAndIsDesksNearMeMethods < ActiveRecord::Migration
  class Instance < ActiveRecord::Base
    has_many :domains, as: :target
    def self.default_instance
      self.find_by_default_instance(true)
    end
  end

  class Domain < ActiveRecord::Base
    belongs_to :target, :polymorphic => true
  end

  class Industry < ActiveRecord::Base
  end

  def up
    add_column :domains, :use_as_default, :boolean, default: false
    Domain.create_with(use_as_default: true, target_type: 'Instance', target_id: Instance.first.id).find_or_create_by(name: 'desksnear.me')
    if Rails.env.development?
      Domain.create_with(use_as_default: true, target_type: 'Instance', target_id: Instance.first.id).find_or_create_by(name: 'localhost')
      Domain.create_with(use_as_default: true, target_type: 'Instance', target_id: Instance.first.id).find_or_create_by(name: '127.0.0.1')
    end
    Instance.find_each do |i|
      if i.domains.where(use_as_default: true).count.zero? && i.domains.count > 0
        i.domains.first.update_attribute(:use_as_default, true)
      end
    end
    add_column :industries, :instance_id, :integer
    Industry.update_all(instance_id: Instance.first.id)
    remove_column :instances, :default_instance
  end

  def down
    add_column :instances, :default_instance, :boolean
    Instance.first.update_attribute(:default_instance, true)
    remove_column :industries, :instance_id
    remove_column :domains, :use_as_default
  end
end