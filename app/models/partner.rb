class Partner < ActiveRecord::Base
  include DomainsCacheable
  auto_set_platform_context

  has_paper_trail
  AVAILABLE_SEARCH_SCOPE_OPTIONS = {'No scoping' => 'no_scoping', 'All associated listings' => 'all_associated_listings'}

  # attr_accessible :name, :domain_attributes, :theme_attributes, :search_scope_option
  belongs_to :instance
  has_one :domain, :as => :target, :dependent => :destroy
  has_one :theme, :as => :owner, :dependent => :destroy

  accepts_nested_attributes_for :domain, reject_if: proc { |params| params[:name].blank? }
  accepts_nested_attributes_for :theme, reject_if: proc { |params| params[:name].blank? }

  validates_presence_of :name

  # we overwrite this method to fallback to instance's theme
  def theme
    super.presence || get_or_build_theme_from_instance
  end

  def has_theme?
    self.persisted? && theme.owner_type == 'Partner'
  end

  # we want to give user a chance to easily customize some of the attributes, so we just copy them from instance
  # if object is created, user had his chance
  def get_or_build_theme_from_instance
    self.new_record? ? build_theme_from_instance : instance.theme
  end

  def build_theme_from_instance
    if instance.present?
      new_theme = instance.theme.build_clone
      new_theme.owner = self
      self.theme = new_theme
    end
  end

  def white_label_enabled?
    true
  end

  def search_scope_option
    super.try(:inquiry)
  end
end

