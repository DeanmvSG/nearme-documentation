class Theme < ActiveRecord::Base
  DEFAULT_EMAIL = 'support@desksnear.me'
  DEFAULT_PHONE_NUMBER = '1.888.998.3375'
  COLORS = %w(blue red orange green gray black white)
  COLORS_DEFAULT_VALUES = %w(024fa3 e83d33 FF8D00 157A49 394449 1e2222 fafafa)
  COLORS.each do |color|
    attr_accessible "color_#{color}"
  end

  attr_accessible :name, :icon_image, :icon_retina_image, :favicon_image,
    :logo_image, :logo_retina_image, :hero_image, :skip_compilation,
    :owner, :owner_id, :owner_type, :site_name, :description, :tagline, :address, :support_email,
    :contact_email, :phone_number, :support_url, :blog_url, :twitter_url, :facebook_url,
    :meta_title, :remote_logo_image_url, :remote_logo_retina_image_url, :remote_icon_image_url,
    :remote_hero_image_url, :remote_icon_retina_image_url, :gplus_url, :homepage_content, :call_to_action

  # TODO: We may want the ability to have multiple themes, and draft states,
  #       etc.
  belongs_to :owner, :polymorphic => true
  has_many :pages, :dependent => :destroy
  delegate :bookable_noun, :to => :instance
  delegate :lessor, :to => :instance
  delegate :lessee, :to => :instance

  mount_uploader :icon_image, ThemeImageUploader
  mount_uploader :icon_retina_image, ThemeImageUploader
  mount_uploader :favicon_image, ThemeImageUploader
  mount_uploader :logo_image, ThemeImageUploader
  mount_uploader :logo_retina_image, ThemeImageUploader
  mount_uploader :hero_image, ThemeImageUploader
  mount_uploader :compiled_stylesheet, ThemeStylesheetUploader

  # Precompile the theme, unless we're saving the compiled stylesheet.
  after_save :recompile_theme, :if => :theme_changed?

  # Validations
  COLORS.each do |color|
    validates "color_#{color}".to_sym, :hex_color => true, :allow_blank => true
  end
  
  # If true, will skip compiling the theme when saving
  attr_accessor :skip_compilation

  def recompile_theme
    CompileThemeJob.perform(self) unless skip_compilation
  end

  def default_mailer
    EmailTemplate.new(from: contact_email,
                      reply_to: contact_email)
  end

  def contact_email
    read_attribute(:contact_email) || DEFAULT_EMAIL
  end

  def phone_number
    read_attribute(:phone_number) || DEFAULT_PHONE_NUMBER
  end

  # Checks if any of options that impact the theme stylesheet have been changed.
  def theme_changed?
    attrs = attributes.keys - %w(updated_at compiled_stylesheet name homepage_content call_to_action address favicon_image)
    attrs.any? { |attr|
      send("#{attr}_changed?")
    }
  end

  def to_liquid
    ThemeDrop.new(self)
  end

  def skipping_compilation(&blk)
    begin
      before, self.skip_compilation = self.skip_compilation, true
      yield(self)
    ensure
      self.skip_compilation = before
    end
    self
  end

  def is_desksnearme?
    self.id == 1
  end

  def instance
    @instance ||= begin
      case owner_type
      when "Instance"
        owner
      when "Company"
        owner.instance
      when "Partner"
        owner.instance
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
    ['id', 'name', 'compiled_stylesheet', 'owner_id', 'owner_type', 'created_at', 'updated_at'].each do |forbidden_attribute|
      current_attributes.delete(forbidden_attribute)
    end
    current_attributes.keys.each do |attribute|
      if attribute.include?('_image')
        url = self.send("#{attribute}_url")
        if url[0] == "/"
          Rails.logger.debug "local file storage not supported"
        else
          cloned_theme.send("remote_#{attribute}_url=", url)
        end if url
        current_attributes.delete(attribute)
      end
    end
    cloned_theme.attributes = current_attributes
    cloned_theme
  end

  def hex_color(color)
    raise ArgumentError unless COLORS.include?(color.to_s)
    value = send(:"color_#{color}")
    return "" if value.to_s.empty?
    "#" + value
  end

  def favicon_image_changed?
    attributes[:favicon_image] ? super : false
  end
end

