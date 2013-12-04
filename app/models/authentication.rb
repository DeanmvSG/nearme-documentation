class Authentication < ActiveRecord::Base
  class InvalidToken < Exception; end;

  attr_accessible :user_id, :provider, :uid, :info, :token, :secret,
    :token_expires_at, :token_expires, :token_expired, :profile_url

  belongs_to :user

  validates :provider, :uid, :token, presence: true
  validates :provider, uniqueness: { scope: :user_id }
  validates :uid,      uniqueness: { scope: :provider }

  serialize :info, Hash

  delegate :new_connections, to: :social_connection

  scope :with_valid_token, -> {
    where('authentications.token_expires_at > ? OR authentications.token_expires_at IS NULL').
    where(token_expired: false)
  }

  scope :with_profile_url, -> {
    where('profile_url IS NOT NULL')
  }

  after_create :find_friends

  AVAILABLE_PROVIDERS = ["Facebook", "LinkedIn", "Twitter" ]

  def social_connection
    @social_connection ||= "Authentication::#{provider_name.capitalize}Provider".constantize.new(self)
  end

  def provider_name
    provider.titleize
  end

  def self.available_providers
    AVAILABLE_PROVIDERS
  end

  def can_be_deleted?
    # we can delete authentication if user has other option to log in, i.e. has set password or other authentications
    user.has_password? || user.authentications.size > 1
  end

  def expire_token!
    self.update_attribute(:token_expired, true)
  end

  private

  def find_friends
    FindFriendsJob.perform(self)
  end
end
