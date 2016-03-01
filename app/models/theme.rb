class Theme < ActiveRecord::Base
  include DomainsCacheable
  has_paper_trail :ignore => [:updated_at]
  auto_set_platform_context
  acts_as_paranoid
  DEFAULT_EMAIL = 'support@desksnear.me'
  DEFAULT_PHONE_NUMBER = '1.888.998.3375'
  COLORS = %w(blue red orange green gray black white)
  COLORS_DEFAULT_VALUES = %w(41bf8b e83d33 FF8D00 6651af 394449 1e2222 fafafa)

  # TODO: We may want the ability to have multiple themes, and draft states,
  #       etc.
  belongs_to :owner, :polymorphic => true
  has_many :pages, :dependent => :destroy
  has_many :content_holders, :dependent => :destroy
  has_one :theme_font, :dependent => :destroy
  delegate :bookable_noun, :to => :instance
  delegate :lessor, :to => :instance
  delegate :lessee, :to => :instance

  accepts_nested_attributes_for :theme_font, reject_if: proc { |params|
    ThemeFont::FONT_TYPES.map do |font_type|
      ThemeFont::FONT_EXTENSIONS.map do |file_extension|
        params["#{font_type}_#{file_extension}".to_sym].present?
      end
    end.flatten.all?{|f| !f}
  }

  validates :tagline, length: { maximum: 255 }
  validates :contact_email, presence: true, email: true, if: lambda { |t| t.owner.try(:domains).try(:first).present? }
  validates :support_email, presence: true, email: true, if: lambda { |t| t.owner.try(:domains).try(:first).present? }
  validates_length_of :description, :maximum => 250

  mount_uploader :icon_image, ThemeImageUploader
  mount_uploader :icon_retina_image, ThemeImageUploader
  mount_uploader :favicon_image, ThemeImageUploader
  mount_uploader :logo_image, ThemeImageUploader
  mount_uploader :logo_retina_image, ThemeImageUploader
  mount_uploader :hero_image, ThemeImageUploader

  # Don't delete the from s3
  skip_callback :commit, :after, :remove_icon_image!
  skip_callback :commit, :after, :remove_icon_retina_image!
  skip_callback :commit, :after, :remove_favicon_image!
  skip_callback :commit, :after, :remove_logo_image!
  skip_callback :commit, :after, :remove_logo_retina_image!
  skip_callback :commit, :after, :remove_hero_image!

  # Validations
  COLORS.each do |color|
    validates "color_#{color}".to_sym, :hex_color => true, :allow_blank => true
  end

  before_validation :unhexify_colors
  before_save :add_no_follow_to_unknown_links, :if => lambda { |theme| theme.homepage_content.present? && theme.homepage_content_changed? }

  def contact_email_with_fallback
    read_attribute(:contact_email).presence || DEFAULT_EMAIL
  end

  def phone_number
    read_attribute(:phone_number) || DEFAULT_PHONE_NUMBER
  end

  def to_liquid
    @theme_drop ||= ThemeDrop.new(self)
  end

  def instance
    @instance ||= begin
      case owner_type
      when "Instance"
        owner
      when "Company"
        (owner || Company.with_deleted.where(id: owner_id).first).try(:instance)
      when "Partner"
        owner.try(:instance)
      else
        raise "Unknown owner #{owner_type}"
      end
    end
  end

  def is_company_theme?
    owner_type == 'Company'
  end

  def build_clone
    current_attributes = attributes
    cloned_theme = Theme.new
    ['id', 'name', 'owner_id', 'owner_type', 'created_at', 'updated_at', 'deleted_at'].each do |forbidden_attribute|
      current_attributes.delete(forbidden_attribute)
    end

    current_attributes.keys.each do |attribute|
      if attribute =~ /_image$/
        url = self.send("#{attribute}_url")
        if url[0] == "/"
          Rails.logger.debug "local file storage not supported"
        else
          cloned_theme.send("remote_#{attribute}_url=", url)
        end if url
        current_attributes.delete(attribute)
      end
    end
    current_attributes.each do |k, v|
      cloned_theme.send("#{k}=", v)
    end
    cloned_theme
  end

  def hex_color(color)
    raise ArgumentError unless COLORS.include?(color.to_s)
    value = send(:"color_#{color}")
    return "" if value.to_s.empty?
    self.class.hexify(value)
  end

  def favicon_image_changed?
    attributes[:favicon_image] ? super : false
  end

  def self.hexify(color)
    '#' + color.to_s.delete('#')
  end

  def self.unhexify(color)
    color.to_s.delete('#')
  end

  def self.default_value_for_color(color)
    COLORS_DEFAULT_VALUES[COLORS.index(color)]
  end

  def twitter_handle
    twitter_url.to_s.scan(/\w+/).last
  end

  def logo_image_dimensions
    { :width => 240, :height => 60}
  end

  def logo_retina_image_dimensions
    { :width => 240, :height => 60}
  end

  def favicon_image_dimensions
    { :width => 32, :height => 32}
  end

  def icon_image_dimensions
    { :width => 60, :height => 60}
  end

  def icon_retina_image_dimensions
    { :width => 60, :height => 60}
  end

  def hero_image_dimensions
    { :width => 250, :height => 202}
  end

  private

  def unhexify_colors
    COLORS.each do |color|
      value = self.send("color_#{color}")
      self.send(:"color_#{color}=", Theme.unhexify(value))
    end
  end

  def add_no_follow_to_unknown_links
    rel_no_follow_adder = RelNoFollowAdder.new({:skip_domains => Domain.pluck(:name)})
    self.homepage_content = rel_no_follow_adder.modify(self.homepage_content)
  end
end

