class InstanceAdminRole < ActiveRecord::Base
  has_paper_trail
  has_metadata :without_db_column => true
  auto_set_platform_context :allow_nil => [:instance_id]
  scoped_to_platform_context :allow_nil => true

  PERMISSIONS = %w(Analytics Settings Theme Manage Blog Support)

  # attr_accessible :permission_analytics, :permission_settings, :permission_theme, :permission_transfers, :permission_inventories,
  #   :permission_partners, :permission_users, :permission_pages, :permission_manage, :permission_blog, :permission_support, :name


  has_many :instance_admins
  belongs_to :instance

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :instance_id

  after_destroy :assign_default_role_to_instance_admins

  default_scope -> { order("name ASC") }

  def self.administrator_role
    self.find_by_name_and_instance_id('Administrator', nil)
  end

  def self.default_role
    self.find_by_name_and_instance_id('Default', nil)
  end

  def assign_default_role_to_instance_admins
    instance_admins.find_each do |instance_admin|
      instance_admin.assign_default_role
      instance_admin.save!
    end
  end

  def first_permission_have_access_to
    PERMISSIONS.find { |p| self.send("permission_#{p.downcase}") }.try(:downcase)
  end

end
