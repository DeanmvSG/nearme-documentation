class User < ActiveRecord::Base
  has_paper_trail :ignore => [:remember_token, :remember_created_at, :sign_in_count, :current_sign_in_at, :last_sign_in_at, 
                              :current_sign_in_ip, :last_sign_in_ip, :updated_at, :failed_attempts, :authentication_token, 
                              :unlock_token, :locked_at, :google_analytics_id, :browser, :browser_version, :platform,
                              :bookings_count, :guest_rating_average, :guest_rating_count, :host_rating_average, 
                              :host_rating_count, :avatar_versions_generated_at, :last_geolocated_location_longitude, 
                              :last_geolocated_location_latitude]

  extend FriendlyId
  friendly_id :name, use: :slugged

  before_save :ensure_authentication_token
  before_save :update_notified_mobile_number_flag

  # Includes billing gateway method and charge association
  include Billing::User

  acts_as_paranoid

  has_many :authentications,
           :dependent => :destroy

  has_many :company_users, dependent: :destroy
  has_many :companies, :through => :company_users, :order => "company_users.created_at ASC"

  has_many :created_companies,
           :class_name => "Company",
           :foreign_key => "creator_id",
           :inverse_of => :creator

  has_many :administered_locations,
           :class_name => "Location",
           :foreign_key => "administrator_id",
           :inverse_of => :administrator

  has_many :administered_listings,
           :class_name => "Listing",
           :through => :administered_locations,
           :source => :listings

  has_many :instance_admins,
           :foreign_key => "user_id",
           :dependent => :destroy

  attr_accessible :companies_attributes
  attr_accessor :skip_password
  accepts_nested_attributes_for :companies

  has_many :locations,
           :through => :companies

  has_many :reservations,
           :foreign_key => :owner_id


  has_many :listings,
           :through => :locations

  has_many :photos,
           :foreign_key => "creator_id"

  has_many :listing_reservations,
           :through => :listings,
           :source => :reservations

  has_many :relationships,
           :class_name => "UserRelationship",
           :foreign_key => "follower_id",
           :dependent => :destroy

  has_many :followed_users,
           :through => :relationships,
           :source => :followed

  has_many :reverse_relationships,
           :class_name => "UserRelationship",
           :foreign_key => "followed_id",
           :dependent => :destroy

  has_many :followers,
           :through => :reverse_relationships,
           :source => :follower

  has_many :host_ratings, class_name: 'HostRating', foreign_key: 'subject_id'
  has_many :guest_ratings, class_name: 'GuestRating', foreign_key: 'subject_id'

  has_many :user_industries
  has_many :industries, :through => :user_industries

  has_many :mailer_unsubscriptions

  belongs_to :partner
  belongs_to :instance
  belongs_to :domain

  after_destroy :cleanup
  after_destroy :mark_email_as_deleted
  before_recover :unmark_email_as_deleted

  scope :patron_of, lambda { |listing|
    joins(:reservations).where(:reservations => { :listing_id => listing.id }).uniq
  }

  scope :needs_mailchimp_update, -> {
      where("mailchimp_synchronized_at IS NULL OR mailchimp_synchronized_at < updated_at")
  }

  scope :without, lambda { |users|
    users_ids = users.respond_to?(:pluck) ? users.pluck(:id) : Array.wrap(users).collect(&:id)
    users_ids.any? ? where('users.id NOT IN (?)', users_ids) : scoped
  }

  scope :ordered_by_email, order('users.email ASC') 

  scope :visited_listing, ->(listing) {
    joins(:reservations).merge(Reservation.confirmed.past.for_listing(listing)).uniq
  }

  scope :hosts_of_listing, ->(listing) {
    where(:id => listing.administrator.id).uniq
  }

  scope :know_host_of, ->(listing) {
    joins(:followers).where(:user_relationships => {:follower_id => listing.administrator.id}).uniq
  }

  scope :mutual_friends_of, ->(user) {
    joins(:followers).where(:user_relationships => {:follower_id => user.friends.pluck(:id)}).without(user).with_mutual_friendship_source
  }

  scope :with_mutual_friendship_source, -> {
    joins(:followers).select('"users".*, "user_relationships"."follower_id" AS mutual_friendship_source')
  }

  extend CarrierWave::SourceProcessing
  mount_uploader :avatar, AvatarUploader, :use_inkfilepicker => true

  validates_presence_of :name
  validates_presence_of :password, :if => :password_required?
  validates :email, email: true

  # FIXME: This is an unideal coupling of 'required parameters' for specific forms
  #        to the general validations on the User model.
  #        A solution moving forward is to extract the relevant forms into
  #        a 'Form' object containing their own additional validations specific
  #        to their context.
  validates_presence_of :phone, :if => :phone_required
  validates_presence_of :country_name, :if => lambda { phone_required || country_name_required }
  attr_accessor :phone_required, :country_name_required

  validates :current_location, length: {maximum: 50}
  validates :company_name, length: {maximum: 50}
  validates :job_title, length: {maximum: 50}
  validates :skills_and_interests, length: {maximum: 150}
  validates :biography, length: {maximum: 250}

  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :trackable, :validatable, :token_authenticatable, :temporary_token_authenticatable

  attr_accessible :name, :email, :phone, :job_title, :password, :avatar, :avatar_versions_generated_at, :avatar_transformation_data,
    :biography, :industry_ids, :country_name, :mobile_number, :facebook_url, :twitter_url, :linkedin_url, :instagram_url, 
    :current_location, :company_name, :skills_and_interests, :last_geolocated_location_longitude, :last_geolocated_location_latitude,
    :partner_id, :instance_id, :domain_id

  delegate :to_s, :to => :name

  attr_accessor :current_platform_context

  # Build a new user, taking into account session information such as Provider
  # authentication.
  def self.new_with_session(attrs, session)
    user = super
    user.apply_omniauth(session[:omniauth]) if session[:omniauth]
    user
  end

  def apply_omniauth(omniauth)
    self.name = omniauth['info']['name'] if name.blank?
    self.email = omniauth['info']['email'] if email.blank?
    expires_at = omniauth['credentials'] && omniauth['credentials']['expires_at'] ? Time.at(omniauth['credentials']['expires_at']) : nil
    token = omniauth['credentials'] && omniauth['credentials']['token']
    secret = omniauth['credentials'] && omniauth['credentials']['secret']
    authentications.build(:provider => omniauth['provider'],
                          :uid => omniauth['uid'],
                          :info => omniauth['info'],
                          :token => token,
                          :secret => secret,
                          :token_expires_at => expires_at)
  end

  def cancelled_reservations
    reservations.cancelled
  end

  def rejected_reservations
    reservations.rejected
  end

  def expired_reservations
    reservations.expired
  end

  def confirmed_reservations
    reservations.confirmed
  end

  def name
    self[:name].to_s.split.collect{|w| w[0] = w[0].capitalize; w}.join(' ')
  end

  def first_name
    name.split[0...-1].join(' ').presence || name
  end

  # Whether to validate the presence of a password
  def password_required?
    # we want to enforce skipping password for instance_admin/users#create
    return false if self.skip_password == true
    return true if self.skip_password == false
    # We're changing/setting password, or new user and there are no Provider authentications
    !password.blank? || (new_record? && authentications.empty?)
  end

  # Whether the user has - or should have - a password.
  def has_password?
    encrypted_password.present? || password_required?
  end

  # Don't require current_password in order to update from Devise.
  def update_with_password(attrs)
    update_attributes(attrs)
  end

  def generate_random_password!
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    random_pass = ''
    1.upto(8) { |i| random_pass << chars[rand(chars.size-1)] }
    self.password = random_pass
  end

  def linked_to?(provider)
    authentications.where(provider: provider).any?
  end

  def has_phone_and_country?
    country_name.present? && phone.present?
  end

  def phone_or_country_was_changed?
    (phone_changed? && phone_was.blank?) || (country_name_changed? && country_name_was.blank?)
  end

  def full_mobile_number_updated?
    mobile_number_changed? || country_name_changed?
  end

  def update_notified_mobile_number_flag
    self.notified_about_mobile_number_issue_at = nil if full_mobile_number_updated?
    # necessary hack, http://apidock.com/rails/ActiveRecord/RecordNotSaved
    nil
  end

  def notify_about_wrong_phone_number(platform_context)
    unless notified_about_mobile_number_issue_at
      UserMailer.notify_about_wrong_phone_number(platform_context, self).deliver
      update_attribute(:notified_about_mobile_number_issue_at, Time.zone.now)
      IssueLogger.log_issue("[internal] invalid mobile number", email, "#{name} (#{id}) was asked to update his mobile number #{full_mobile_number}")
    end
  end

  def following?(other_user)
    relationships.find_by_followed_id(other_user.id)
  end

  def follow!(other_user, auth = nil)
    relationships.create!(followed_id: other_user.id, authentication_id: auth.try(:id))
  end

  def add_friend(users, auth = nil)
    raise ArgumentError, "Invalid Authentication for User ##{self.id}" if auth && auth.user != self
    Array.wrap(users).each do |user|
      next if self.friends.exists?(user)
      friend_auth = auth.nil? ? nil : user.authentications.where(provider: auth.provider).first
      user.follow!(self, friend_auth)
      self.follow!(user, auth)
    end
  end
  alias_method :add_friends, :add_friend 

  def friends
    self.followed_users.without(self)
  end

  def social_connections
    self.authentications
  end

  def mutual_friendship_source
    self.class.find_by_id(self[:mutual_friendship_source].to_i) if self[:mutual_friendship_source]
  end

  def mutual_friends
    self.class.without(self).mutual_friends_of(self)
  end

  def full_email
    "#{name} <#{email}>"
  end

  def first_name
    name.split(' ', 2)[0]
  end

  def last_name
    name.split(' ', 2)[1]
  end

  def country
    Country.find(country_name) if country_name.present?
  end

  # Returns the mobile number with the full international calling prefix
  def full_mobile_number
    return unless mobile_number.present?

    number = mobile_number
    number = "+#{country.calling_code}#{number.gsub(/^0/, "")}" if country.try(:calling_code)
    number
  end

  def accepts_sms?
    full_mobile_number.present?
  end

  def avatar_changed?
    false
  end

  def default_company
    self.companies.first
  end

  def first_listing
    if companies.first and companies.first.locations.first
      companies.first.locations.first.listings.first
    end
  end

  def has_listing_without_price?
    listings.any?(&:free?)
  end

  def mailchimp_synchronized!
    touch(:mailchimp_synchronized_at)
  end

  def mailchimp_synchronized?
    mailchimp_synchronized_at.present? && mailchimp_synchronized_at >= updated_at
  end

  def mailchimp_exported?
    mailchimp_synchronized_at.present?
  end

  def email_verification_token
    Digest::SHA1.hexdigest(
      "--dnm-token-#{self.id}-#{self.created_at}"
    )
  end

  def verify_email_with_token(token)
    if token.present? && self.email_verification_token == token && !self.verified_at
      self.verified_at = Time.zone.now
      self.save(:validate => false)
      true
    else
      false
    end
  end

  def to_liquid
    UserDrop.new(self)
  end

  def to_param
    caller[0].include?('friendly_id') ? super : id
  end

  def is_location_administrator?
    administered_locations.size > 0
  end

  def listings_with_messages
    listings.with_listing_messages + administered_listings.with_listing_messages
  end

  def listing_messages
    ListingMessage.where('owner_id = ? OR listing_id IN(?)', id, listings_with_messages.map(&:id)).order('created_at asc')
  end

  def listings_in_near(platform_context = nil, results_size = 3, radius_in_km = 100)
    platform_context ||= self.current_platform_context
    return [] if platform_context.nil?

    search_scope = Listing::SearchScope.scope(platform_context)
    locations_in_near = nil
    # we want allow greenwhich and friends, but probably 0 latitude and 0 longitude is not valid location :)
    if last_geolocated_location_latitude.nil? || last_geolocated_location_longitude.nil? || (last_geolocated_location_latitude.to_f.zero? && last_geolocated_location_longitude.to_f.zero?)
      locations_in_near = search_scope.near(current_location, radius_in_km, units: :km, order: :distance)
    else
      locations_in_near = search_scope.near([last_geolocated_location_latitude, last_geolocated_location_longitude], radius_in_km, units: :km, order: :distance)
    end

    listings = []
    locations_in_near.includes(:listings).each do |location|
      listings += location.listings.searchable.limit((listings.size - results_size).abs)
      return listings if listings.size >= results_size
    end if locations_in_near
    listings
  end

  def can_manage_listing?(listing)
    listing.company && listing.company.company_users.where(user_id: self.id).any?
  end

  def administered_locations_pageviews_7_day_total
    scoped_locations = (!companies.count.zero? && self == self.companies.first.creator) ? self.companies.first.locations : administered_locations
    scoped_locations = scoped_locations.with_searchable_listings
    Impression.where('impressionable_type = ? AND impressionable_id IN (?) AND DATE(impressions.created_at) >= ?', 'Location', scoped_locations.pluck(:id), Date.current - 7.days).count
  end

  def unsubscribe(mailer_name)
    mailer_unsubscriptions.create(mailer: mailer_name)
  end

  def unsubscribed?(mailer_name)
    mailer_unsubscriptions.where(mailer: mailer_name).any?
  end

  def set_platform_context(platform_context)
    self.instance_id = platform_context.instance.id
    self.domain_id = platform_context.domain.try(:id)
    self.partner_id = platform_context.partner.try(:id)
    self.save
  end

  def cleanup
    self.created_companies.each do |company|
      if company.company_users.count.zero?
        company.destroy
      # this might not be needed, but just in case...
      elsif company.creator == self
        company.creator = company.company_users.first.user
        company.save!
      end
    end
    self.administered_locations.each do |location|
      location.update_attribute(:administrator_id, nil) if location.administrator_id == self.id
    end
  end

  def mark_email_as_deleted
    self.email = "deleted_#{self.created_at.to_i}_#{self.email}"
    self.save!
  end

  def unmark_email_as_deleted
    self.email = self.email.gsub("deleted_#{self.created_at.to_i}_", '')
    self.save!
  end

  # Returns a temporary token to be used as the login token parameter
  # in URLs to automatically log the user in.
  def temporary_token(expires_at = 48.hours.from_now)
    User::TemporaryTokenVerifier.new(self).generate(expires_at)
  end

  def facebook_url
    social_url('facebook')
  end

  def twitter_url
    social_url('twitter')
  end

  def linkedin_url
    social_url('linkedin')
  end

  def instagram_url
    social_url('instagram')
  end

  def social_url(provider)
    authentications.where(provider: provider).
      where('profile_url IS NOT NULL').
      order('created_at asc').last.try(:profile_url)
  end

end
