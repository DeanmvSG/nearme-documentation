class Topic < ActiveRecord::Base
  has_paper_trail
  acts_as_paranoid
  auto_set_platform_context
  scoped_to_platform_context

  belongs_to :category
  attr_readonly :followers_count

  has_many :activity_feed_events, as: :event_source, dependent: :destroy
  has_many :activity_feed_subscriptions, as: :followed
  has_many :data_source_contents, through: :data_source
  has_many :feed_followers, through: :activity_feed_subscriptions, source: :follower
  has_many :projects, through: :project_topics
  has_many :project_topics
  has_many :users, through: :user_topics
  has_many :user_topics

  has_one :data_source, as: :data_sourcable

  has_and_belongs_to_many :user_status_updates

  accepts_nested_attributes_for :data_source

  scope :featured, -> { where(featured: true) }

  after_commit :create_activity_feed_event, on: :create

  mount_uploader :image, TopicImageUploader
  mount_uploader :cover_image, TopicCoverImageUploader

  validates :name, presence: true

  def create_activity_feed_event
    event = :topic_created
    affected_objects = [self] + self.projects.to_a
    ActivityFeedService.create_event(event, self, affected_objects, self)
  end

  def all_projects
    projects
  end

  def self.search_by_query(attributes = [], query)
    if query.present?
      words = query.split.map.with_index{|w, i| ["word#{i}".to_sym, "%#{w}%"]}.to_h

      sql = attributes.map do |attrib|
        attrib = "#{quoted_table_name}.\"#{attrib}\""
        words.map do |word, value|
          "#{attrib} ILIKE :#{word}"
        end
      end.flatten.join(' OR ')

      where(ActiveRecord::Base.send(:sanitize_sql_array, [sql, words]))
    else
      all
    end
  end

  def to_liquid
    @topic_drop ||= TopicDrop.new(self)
  end
end