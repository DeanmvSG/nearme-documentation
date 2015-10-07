class BlogPost < ActiveRecord::Base
  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :history, :finders]

  include Taggable

  belongs_to :blog_instance
  belongs_to :user, -> { with_deleted }

  delegate :instance, to: :blog_instance

  before_validation :sanitize_content
  validates_presence_of :blog_instance, :user, :title, :content, :published_at

  mount_uploader :header, HeroImageUploader
  mount_uploader :author_avatar, SimpleAvatarUploader

  scope :by_date, -> { order('COALESCE(published_at, created_at) DESC') }
  scope :published, -> { where("published_at < ? OR published_at IS NULL", Time.zone.now ) }


  def previous_blog_post
    @previous_blog_post ||= blog_instance.blog_posts
                                         .published
                                         .order('published_at DESC')
                                         .where('published_at < ?', published_at)
                                         .first
  end

  def next_blog_post
    @next_blog_post ||= blog_instance.blog_posts
                                     .published
                                     .order('published_at DESC')
                                     .where('published_at > ?', published_at)
                                     .last
  end

  def slug_changed?
    return false if title.blank? && slug.blank?
    title.parameterize != slug
  end

  def to_liquid
    @blog_post_drop ||= BlogPostDrop.new(self)
  end

  private

  def sanitize_content
    self.content = nil if self.content.to_s.gsub(/<\/?[^>]*>/, "").empty?
  end

  def should_generate_new_friendly_id?
    slug.blank? || title_changed?
  end

  def slug_candidates
    [
      :title,
      [:title, published_at.strftime("%b %d %Y")]
    ]
  end
end
