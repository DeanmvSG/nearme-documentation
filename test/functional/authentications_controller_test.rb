require 'test_helper'

class AuthenticationsControllerTest < ActionController::TestCase

  setup do
    @password = "password123"
  end


  # Social Authentication

  test "authentication can be deleted if user has password set" do
    create_signed_in_user_with_authentication
    stub_mixpanel
    @tracker.expects(:disconnected_social_provider).once.with do |user, custom_options|
      user == @user && custom_options == { provider: @user.authentications.first.provider }
    end
    assert_difference('@user.authentications.count', -1) do
      delete :destroy, id: @user.authentications.first.id
    end
  end

  test "authentication can be deleted if user has no  password but more than one authentications" do
    create_signed_in_user_with_authentication
    add_authentication("twitter", "abc123")
    stub_mixpanel
    @tracker.expects(:disconnected_social_provider).once.with do |user, custom_options|
      user == @user && custom_options == { provider: @user.authentications.first.provider }
    end
    assert_difference('@user.authentications.count', -1) do
      delete :destroy, id: @user.authentications.first.id
    end
  end

  test "authentication cannot be deleted if user has no password and one authentication" do
    create_no_password_signed_in_user_and_authentication
    assert_log_not_triggered(:disconnected_social_provider)
    assert_no_difference('@user.authentications.count') do
      delete :destroy, id: @user.authentications.first.id
    end
  end


  context 'authentication flow' do

    setup do
      @provider = 'twitter'
      @uid = '123456'
      @email = 'test@example.com'
      @token = 'abcd'
      @secret = 'dcba'
      @user = FactoryGirl.create(:user)
      request.env['omniauth.auth'] = {
        'provider' => @provider,
        'uid' => @uid,
        'info' => { 'email' => @email, 'name' => 'maciek', 'urls' => {'Twitter' => 'https://twitter.com/desksnearme'}},
        'credentials' => {
          'token' => @token,
          'secret' => @secret,
          'expires_at' => 123456789
        }
      }
    end

    should "redirect with message if already connected" do
      @other_user = FactoryGirl.create(:user)
      add_authentication(@provider, @uid, @other_user)
      sign_in @user
      assert_no_difference('User.count') do
        assert_no_difference('Authentication.count') do
          post :create
        end
      end
      assert flash[:error].include?('already connected to other user')
    end

    should "successfully sign in and log" do
      add_authentication(@provider, @uid, @user)
      stub_mixpanel
      @tracker.expects(:logged_in).once.with do |user, custom_options|
        user == @user && custom_options == { provider: @provider }
      end
      Authentication.any_instance.expects(:update_info)

      assert_no_difference('User.count') do
        assert_no_difference('Authentication.count') do
          post :create
        end
      end
      assert flash[:success].include?('Signed in successfully')
    end

    should "successfully create new authentication and log" do
      sign_in @user
      stub_mixpanel
      Rails.application.config.expects(:perform_social_jobs).twice.returns(true)
      raw = OpenStruct.new(id: 'dnm', username: 'desksnearme', name: 'Desks Near Me', url: 'https://twitter.com/desksnearme')
      raw.stubs(:profile_image_url).returns(nil)
      Twitter::REST::Client.any_instance.stubs(:user).once.returns(raw)
      Twitter::REST::Client.any_instance.stubs(:friend_ids).once.returns(['1', '2'])
      Authentication.any_instance.stubs(:token_expired?).returns(false)
      @tracker.expects(:connected_social_provider).once.with do |user, custom_options|
        user == @user && custom_options == { provider: @provider }
      end
      assert_no_difference('User.count') do
        assert_difference('Authentication.count') do
          post :create
        end
      end
      assert_equal 'Authentication successful.', flash[:success]
      assert_equal @token, @user.authentications.last.token
      assert_equal @secret, @user.authentications.last.secret
      assert_equal 'https://twitter.com/desksnearme', @user.authentications.last.profile_url
    end

    should "successfully create new authentication as alternative to setting password" do
      @user = FactoryGirl.create(:user_without_password)
      sign_in @user
      stub_mixpanel
      @tracker.expects(:connected_social_provider).once.with do |user, custom_options|
        user == @user && custom_options == { provider: @provider }
      end
      assert_no_difference('User.count') do
        assert_difference('Authentication.count') do
          post :create
        end
      end
      assert_equal 'Authentication successful.', flash[:success]
    end

    should "fail due to incorrect email" do
      FactoryGirl.create(:user, :email => @email)
      sign_in @user
      assert_no_difference('User.count') do
        assert_no_difference('Authentication.count') do
          post :create
        end
      end
      assert flash[:error].include?('Your Twitter email is already linked to an account')
    end

    context "should successfully sign up and log"  do
      setup do
        stub_mixpanel
      end

      should "is tracked via mixpanel" do
        @tracker.expects(:signed_up).once.with do |user, custom_options|
          user == assigns(:oauth).authenticated_user && custom_options == { signed_up_via: 'other', provider: @provider }
        end
        @tracker.expects(:connected_social_provider).once.with do |user, custom_options|
          user == assigns(:oauth).authenticated_user && custom_options == {  provider: @provider }
        end

        post :create
      end

      should 'create user with auth.' do
        assert_difference('User.count') do
          assert_difference('Authentication.count') do
            post :create
          end
        end

        assert_equal @token, User.last.authentications.last.token
        assert_equal @secret, User.last.authentications.last.secret
      end
    end

    should "redirect to fill missing information if cannot create user" do
      request.env['omniauth.auth'] = { 'provider' => @provider, 'uid' => @uid, 'info' => { } }
      assert_no_difference('User.count') do
        assert_no_difference('Authentication.count') do
          post :create
        end
      end
      assert_redirected_to new_user_registration_url
    end

    context 'token params after login' do
      setup do
        add_authentication(@provider, @uid, @user)
        stub_mixpanel
      end

      should 'change token_expires_at to date expires day' do
        time = request.env['omniauth.auth']['credentials']['expires_at'] = (Time.now + 60.days).to_i
        post :create
        auth = Authentication.last
        assert auth.token_expires?, 'auth token is not marked as expirable'
        assert_equal time, auth.token_expires_at.to_i, "auth token should expire in #{time}"
      end

      should 'change expires to false for non-expiring token' do
        request.env['omniauth.auth']['credentials'].delete('expires_at')
        post :create
        auth = Authentication.last
        refute auth.token_expires?, 'auth token is marked as expirable'
        assert_nil auth.token_expires_at, 'auth token has expires_at time'
      end
    end
  end

  private

  def add_authentication(provider, uid, user = nil)
    user ||= @user
    auth = user.authentications.build
    auth.provider = provider
    auth.uid = uid
    auth.token = "token"
    auth.save!
  end

  def create_no_password_signed_in_user_and_authentication
    create_signed_in_user_with_authentication(false)
  end

  def create_signed_in_user_with_authentication(with_password = true)
    @user = FactoryGirl.build(:user, password: nil, password_confirmation: nil)
    @user.password = @user.password_confirmation = @password if with_password
    @user.instance_id = PlatformContext.current.instance.id
    @user.save!(validate: false)
    sign_in @user
    add_authentication("facebook", "123456")
    @user.authentications.each do |auth|
      auth.user = @user
      auth.user.save!
    end
  end

end
