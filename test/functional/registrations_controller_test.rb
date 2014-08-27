require 'test_helper'

class RegistrationsControllerTest < ActionController::TestCase

  setup do
    @user = FactoryGirl.create(:user)
    @request.env["devise.mapping"] = Devise.mappings[:user]
    stub_mixpanel
    PostActionMailer.stubs(:sign_up_verify).returns(stub(deliver: true))
  end

  context 'actions' do

    should 'successfully sign up and track' do
      @tracker.expects(:signed_up).with do |user, custom_options|
        user == assigns(:user) && custom_options == { referrer_id: Instance.default_instance.id, referrer_type: 'Instance', signed_up_via: 'other', provider: 'native' }
      end
      assert_difference('User.count') do
        post :create, user: user_attributes
      end

    end

    should 'successfully update' do
      sign_in @user
      @industry = FactoryGirl.create(:industry)
      @industry2 = FactoryGirl.create(:industry)
      @tracker.expects(:updated_profile_information).once
      FactoryGirl.create(:transactable_type)
      put :update, :id => @user, user: { :industry_ids => [@industry.id, @industry2.id] }
      @user.reload
      assert_equal [@industry.id, @industry2.id], @user.industries.collect(&:id)
    end

    should 'show profile' do
      sign_in @user

      get :show, :id => @user.slug

      assert_response 200
      assert_select "h1", @user.name
      assert_select ".info h2", "Manager at DesksNearMe"
      assert_select ".info h4", "Prague"
      assert_select ".info h4", "Skills &amp; Interests"
      assert_select ".info .icon .ico-mail", 1

      assert_select ".info .icon .ico-facebook-full", 0
      assert_select ".info .icon .ico-linkedin", 0
      assert_select ".info .icon .ico-twitter", 0
      assert_select ".info .icon .ico-instagram", 0
    end

    should 'show profile with connections' do
      sign_in @user

      fb = FactoryGirl.create(:authentication, provider: 'facebook', total_social_connections: 10)
      ln = FactoryGirl.create(:authentication, provider: 'linkedin', total_social_connections: 0)
      tw = FactoryGirl.create(:authentication, provider: 'twitter', total_social_connections: 5)
      ig = FactoryGirl.create(:authentication, provider: 'instagram', total_social_connections: 1, profile_url: 'link')
      @user.authentications << [fb, ln, tw, ig]


      get :show, :id => @user.slug

      assert_response 200
      assert_select ".info .icon .ico-facebook-full", 1
      assert_select ".info .icon .ico-linkedin", 1
      assert_select ".info .icon .ico-twitter", 1
      assert_select ".info .icon .ico-instagram", 1
      assert_select ".info .icon .ico-mail", 1
      assert_select ".info .connection .count", "10 friends"
      assert_select ".info .connection .count", "0 connections"
      assert_select ".info .connection .count", "5 followers"
    end

    should 'successfully unsubscribe' do
      verifier = ActiveSupport::MessageVerifier.new(DesksnearMe::Application.config.secret_token)
      signature = verifier.generate("recurring_mailer/analytics")

      assert_difference('ActionMailer::Base.deliveries.size', 1) do
        get :unsubscribe, :token => @user.authentication_token, :signature => signature
      end
      assert @user.unsubscribed?("recurring_mailer/analytics")
      assert_redirected_to root_path
    end
  end

  context "verify" do

    should "verify user if token and id are correct" do
      get :verify, :id => @user.id, :token => @user.email_verification_token
      @user.reload
      @controller.current_user.id == @user.id
      assert @user.verified_at
    end

    should "redirect verified user with listing to dashboard" do
      @company = FactoryGirl.create(:company, :creator => @user)
      @location = FactoryGirl.create(:location, :company => @company)
      FactoryGirl.create(:transactable, :location => @location)
      get :verify, :id => @user.id, :token => @user.email_verification_token
      assert_redirected_to manage_locations_path
    end

    should "redirect verified user without listing to settings" do
      get :verify, :id => @user.id, :token => @user.email_verification_token
      assert_redirected_to edit_user_registration_path
    end

    should "handle situation when user is verified" do
      @user.verified_at = Time.zone.now
      @user.save!
      get :verify, :id => @user.id, :token => @user.email_verification_token
      @user.reload
      assert_nil @controller.current_user
      assert @user.verified_at
    end

    should "not verify user if id is incorrect" do
      assert_raise ActiveRecord::RecordNotFound do
        get :verify, :id => (@user.id+1), :token => @user.email_verification_token
      end
    end

    should "not verify user if token is incorrect" do
      get :verify, :id => @user.id, :token => @user.email_verification_token+"incorrect"
      @user.reload
      assert_nil @controller.current_user
      assert !@user.verified_at
      assert_redirected_to root_path
    end

  end

  context 'referer and source=&campaign=' do

    setup do
      ApplicationController.class_eval do
        def first_time_visited?; @first_time_visited = cookies.count.zero?; end
      end
    end

    context 'on first visit' do
      should 'be stored in both cookie and db' do
        @request.env['HTTP_REFERER'] = 'http://example.com/'
        get :new, source: 'xxx', campaign: 'yyy'
        assert_equal 'xxx', cookies.signed[:source]
        assert_equal 'yyy', cookies.signed[:campaign]
        assert_equal 'http://example.com/', cookies.signed[:referer]

        post :create, user: user_attributes
        user = User.find_by_email('user@example.com')
        assert_equal 'xxx', user.source
        assert_equal 'yyy', user.campaign
        assert_equal 'http://example.com/', user.referer
      end
    end

    context 'on repeated visits' do
      should 'be stored only on first visit' do
        @request.env['HTTP_REFERER'] = 'http://example.com/'
        get :new
        assert_nil cookies.signed[:source]
        assert_nil cookies.signed[:campaign]
        assert_equal 'http://example.com/', cookies.signed[:referer]

        @request.env['HTTP_REFERER'] = 'http://homepage.com/'
        get :new, source: 'xxx', campaign: 'yyy'
        assert_nil cookies.signed[:source]
        assert_nil cookies.signed[:campaign]
        assert_equal 'http://example.com/', cookies.signed[:referer]

        post :create, user: user_attributes
        user = User.find_by_email('user@example.com')
        assert_nil user.source
        assert_nil user.campaign
        assert_equal 'http://example.com/', user.referer
      end
    end

    context 'avatar' do

      should 'store transformation data and rotate' do
        sign_in @user
        stub_image_url("http://www.example.com/image.jpg")
        post :update_avatar, { :crop => { :w => 1, :h => 2, :x => 10, :y => 20 }, :rotate => 90 }
        @user = assigns(:user)
        assert_not_nil @user.avatar_transformation_data
        assert_equal({ 'w' => '1', 'h' => '2', 'x' => '10', 'y' => '20' }, @user.avatar_transformation_data[:crop])
        assert_equal "90", @user.avatar_transformation_data[:rotate]
      end

      should 'delete everything related to avatar when destroying avatar' do
        sign_in @user
        @user.avatar_transformation_data = { :crop => { :w => 1 } }
        @user.avatar_versions_generated_at = Time.zone.now
        @user.avatar_original_url = "example.jpg"
        @user.save!
        delete :destroy_avatar, { :crop => { :w => 1, :h => 2, :x => 10, :y => 20 }, :rotate => 90 }
        @user = assigns(:user)
        assert @user.avatar_transformation_data.empty?
        assert_nil @user.avatar_versions_generated_at
        assert_nil @user.avatar_original_url
        assert !@user.avatar.any_url_exists?

      end
    end

  end

  context 'versions' do

    should 'track version change on create' do
      assert_difference('PaperTrail::Version.where("item_type = ? AND event = ?", "User", "create").count') do
        with_versioning do
          post :create, user: user_attributes
        end
      end

    end

    should 'track version change on update' do
      sign_in @user
      FactoryGirl.create(:transactable_type)
      assert_difference('PaperTrail::Version.where("item_type = ? AND event = ?", "User", "update").count') do
        with_versioning do
          put :update, :id => @user, user: { :name => 'Updated Name' }
        end
      end
    end
  end

  context 'scopes current partner' do

    setup do
      @instance = FactoryGirl.create(:instance)
      @domain = FactoryGirl.create(:domain)
      @partner = FactoryGirl.create(:partner)
    end

    should 'match partner_id and instance_id' do
      PlatformContext.any_instance.stubs(:partner).returns(@partner)
      PlatformContext.any_instance.stubs(:domain).returns(@domain)
      PlatformContext.any_instance.stubs(:instance).returns(@instance)
      post :create, user: user_attributes
      user = User.find_by_email('user@example.com')
      assert_equal @partner.id, user.partner_id
      assert_equal @domain.id, user.domain_id
      assert_equal @instance.id, user.instance_id
    end

  end

  context 'sms notifications' do
    setup do
      @user.sms_notifications_enabled = false
      @user.sms_preferences = Hash[%w(user_message reservation_state_changed new_reservation).map{|sp| [sp, '1']}]
      @user.save!
      FactoryGirl.create(:transactable_type)
    end

    should 'save sms_notifications_enabled and sms_preferences' do
      sign_in @user
      put :update_notification_preferences, user: { sms_notifications_enabled: '0', sms_preferences: {new_reservation: '1'}}
      @user.reload
      refute @user.sms_notifications_enabled
      assert_equal @user.sms_preferences, {"new_reservation" => '1'}
    end

    should 'not overwrite sms preferences on profile update' do
      sign_in @user
      assert_equal @user.sms_preferences, {"user_message"=>"1", "reservation_state_changed"=>"1", "new_reservation"=>"1"}
      put :update, :id => @user, user: { name: 'Dave' }
      assert_equal @user.reload.sms_preferences, {"user_message"=>"1", "reservation_state_changed"=>"1", "new_reservation"=>"1"}
    end
  end

  private
  j
  def user_attributes
    { name: 'Test User', email: 'user@example.com', password: 'secret' }
  end

end

