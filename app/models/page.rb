class Page < ActiveRecord::Base
  auto_set_platform_context
  scoped_to_platform_context
  acts_as_paranoid
  has_paper_trail
  class NotFound < ActiveRecord::RecordNotFound; end

  include RankedModel
  ranks :position, with_same: :theme_id

  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders, :scoped], scope: :theme

  include SitemapService::Callbacks

  mount_uploader :hero_image, HeroImageUploader
  skip_callback :commit, :after, :remove_hero_image!

  belongs_to :theme
  belongs_to :instance

  default_scope -> { rank(:position) }

  before_save :convert_to_html, :if => lambda { |page| page.content.present? && (page.content_changed? || page.html_content.blank?) }

  def to_liquid
    @page_drop ||= PageDrop.new(self)
  end

  def redirect?
    redirect_url.present?
  end

  def redirect_url_in_known_domain?
    is_http_https = (redirect_url.downcase =~ /^http|^https/)
    (is_http_https && Domain.pluck(:name).any?{|d| self.redirect_url.include?(d)}) || !is_http_https
  end

  private

  def convert_to_html
    self.html_content = RDiscount.new(self.content).to_html
    rel_no_follow_adder = RelNoFollowAdder.new({:skip_domains => Domain.pluck(:name)})
    self.html_content = rel_no_follow_adder.modify(self.html_content)
  end

  def should_generate_new_friendly_id?
    slug.blank? || path_changed?
  end

  def slug_candidates
    [
      :path,
      [:path, DateTime.now.strftime("%b %d %Y")]
    ]
  end
end
