require 'test_helper'

class AuthenticationTest < ActiveSupport::TestCase
  should validate_presence_of(:provider)
  should validate_presence_of(:uid)

  should validate_uniqueness_of(:provider).scoped_to(:user_id)
  should validate_uniqueness_of(:uid).scoped_to(:provider)

  setup do
    @user = FactoryGirl.build(:user, password: nil)
    @user.save!(validate: false)

    @valid_params = { :provider => "desksnearme",
                      :uid      => "123456789",
                      :user_id  => @user.id }
  end

  context '#connections' do
    should 'return connection count' do
      friend = FactoryGirl.create(:user)
      user_auth = FactoryGirl.create(:authentication, user: @user)
      friend_auth = FactoryGirl.create(:authentication, user: friend)
      @user.add_friend(friend, user_auth)

      refute_equal user_auth.connections, friend_auth.connections
      assert_equal 1, user_auth.connections.count
      assert_equal 1, friend_auth.connections.count
    end
  end

  context 'social connection' do
    class Authentication::DesksnearmeProvider
      def initialize(params)
      end
    end

    should 'call provider' do
      auth = Authentication.new(@valid_params)
      Authentication::DesksnearmeProvider.expects(:new).with(auth)
      auth.social_connection
    end

    should 'have provider for every available provider' do
      Authentication.available_providers.each do |provider|
        assert_nothing_raised {
          "Authentication::#{provider.downcase.capitalize}Provider".constantize
        }
      end
    end
  end

  should "has a hash for info" do
    auth = Authentication.new(@valid_params)
    auth.info["thing"] = "stuff"
    assert_equal "stuff", auth.info["thing"]
  end

  context '.with_valid_token' do
    should "return Authentications with a valid access token" do
      auth = FactoryGirl.create(:authentication, token_expired: false, token_expires_at: 3.days.from_now)
      auth_expired = FactoryGirl.create(:authentication, token_expires_at: 1.week.ago)

      assert Authentication.with_valid_token.include?(auth)
      assert !Authentication.with_valid_token.include?(auth_expired)
    end
  end

  context '#can_be_deleted?' do
    should "not be deleted if user has nil password and he has no other authentications" do
      auth = Authentication.new(@valid_params, :user => User.new)
      auth.user.authentications << auth
      assert_equal false, auth.can_be_deleted?
    end

    should "not be deleted if user has blank password and he has no other authentications" do
      auth = Authentication.new(@valid_params, :user => User.new)
      auth.user.encrypted_password = ''
      auth.user.authentications << auth
      assert_equal false, auth.can_be_deleted?
    end

    should "be deleted if user has not blank password and he has no other authentications" do
      auth = Authentication.new(@valid_params, :user => User.new)
      auth.user.encrypted_password = "aaaaaa"
      auth.user.authentications << auth
      assert_equal true, auth.can_be_deleted?
    end

    should "be deleted if user has blank password but he has other authentications" do
      auth = Authentication.new(@valid_params, :user => User.new)
      auth.user.encrypted_password = ""
      auth.user.authentications << Authentication.new
      auth.user.authentications << auth
      assert_equal true, auth.can_be_deleted?
    end

    should "be deleted if user has not blank password and he has other authentications" do
      auth = Authentication.new(@valid_params, :user => User.new)
      auth.user.encrypted_password = "aaaaaa"
      auth.user.authentications << auth
      auth.user.authentications << Authentication.new
      assert_equal true, auth.can_be_deleted?
    end
  end
end
