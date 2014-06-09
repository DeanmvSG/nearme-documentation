require 'test_helper'

class UserTest < ActiveSupport::TestCase

  include ApplicationHelper

  should have_many(:industries)

  context "#social_connections" do
    should "be empty for new user" do
      user = FactoryGirl.build(:user)
      assert_equal [], user.social_connections
    end

    should "return provider and count for existing connections" do
      user = FactoryGirl.create(:user)
      friend = FactoryGirl.create(:user)
      auth = FactoryGirl.create(:authentication, provider: 'facebook')
      user.authentications << auth
      user.add_friend(friend, auth)
      connections = user.social_connections
      connection = connections.first
      assert_equal 1, connections.length
      assert_equal 'facebook', connection.provider
      assert_equal 1, connection.connections_count
    end
  end

  context "#without" do
    should "handle single user" do
      user = FactoryGirl.create(:user)
      count = User.count
      assert_equal count - 1, User.without(user).count
    end

    should "handle collection" do
      3.times { FactoryGirl.create(:user) }
      users = User.first(2)
      count = User.count

      assert_equal count - 2, User.without(users).count
    end
  end

  context '#add_friend' do
    setup do
      @jimmy = FactoryGirl.create(:user)
      @joe = FactoryGirl.create(:user)
    end

    should 'raise for invalid auth' do
      auth = FactoryGirl.create(:authentication)
      assert_raise(ArgumentError) { @jimmy.add_friend(@joe, auth) }
    end

    should 'creates two way relationship' do
      @jimmy.add_friend(@joe)

      assert_equal [@joe], @jimmy.friends
      assert_equal [@jimmy], @joe.friends
    end
  end

  context 'social scopes' do
    setup do
      @me = FactoryGirl.create(:user)
      @listing = FactoryGirl.create(:transactable)
    end

    context 'visited_listing' do
      should 'find only users with confirmed past reservation for listing in friends' do
        FactoryGirl.create(:reservation, state: 'confirmed')

        4.times { @me.add_friend(FactoryGirl.create(:user)) }

        friends_with_visit = @me.friends.first(2)
        @me.friends.last.reservations << FactoryGirl.create(:future_reservation, state: 'confirmed', date: Date.tomorrow)
        friends_with_visit.each {|f| FactoryGirl.create(:past_reservation, state: 'confirmed', listing: @listing, user:f)}

        assert_equal friends_with_visit.sort, @me.friends.visited_listing(@listing).to_a.sort
      end
    end

    context 'hosts_of_listing' do
      should 'find host of listing in friends' do
        friend1 = FactoryGirl.create(:user)
        @listing.location.update_attribute(:administrator_id, friend1.id)
        @listing.reload
        friend2 = FactoryGirl.create(:user)
        @me.add_friends([friend1, friend2])

        assert_equal [friend1].sort, @me.friends.hosts_of_listing(@listing).sort
      end
    end

    context 'friends_know_host_of' do
      should 'find users knows host' do
        2.times { @me.add_friend(FactoryGirl.create(:user))}
        @friend = FactoryGirl.create(:user)

        @me.add_friend(@friend)

        @listing = FactoryGirl.create(:transactable)
        host = FactoryGirl.create(:user)
        @listing.location.update_attribute(:administrator_id, host.id)
        @listing.reload

        @friend.add_friend(host)

        @me.reload
        assert_equal [@friend], @me.friends_know_host_of(@listing)
      end
    end

    context 'mutual_friends_of' do
      should 'find users with friend that visited listing' do
        @friend = FactoryGirl.create(:user)
        @me.add_friend(@friend)
        mutual_friends = []
        4.times { mutual_friends << FactoryGirl.create(:user); @friend.add_friend(mutual_friends.last) }

        mutual_friends_with_visit = @friend.friends.without(@me).first(2)
        @friend.friends.last.reservations << FactoryGirl.create(:future_reservation, state: 'confirmed', date: Date.tomorrow)
        mutual_friends_with_visit.each {|f| FactoryGirl.create(:past_reservation, state: 'confirmed', listing: @listing, user:f)}

        result = User.mutual_friends_of(@me).visited_listing(@listing)
        assert_equal mutual_friends_with_visit.sort, result.sort
        assert_equal [@friend], result.collect(&:mutual_friendship_source).uniq
      end
    end
  end

  context "validations" do
    context "when no country name provided" do

      context "when country name not required" do
        should "be valid" do
          user = FactoryGirl.build(:user_without_country_name)
          assert user.valid?
        end
      end

      context "when country name required" do
        should "be invalid" do
          user = FactoryGirl.build(:user_without_country_name, :country_name_required => true)
          assert_equal user.valid?, false
        end
      end

    end
  end

  context 'name' do
    setup do
      @user = FactoryGirl.create(:user, name: 'jimmy falcon')
    end

    should 'have capitalized name' do
      assert_equal "Jimmy Falcon", @user.name
    end

    should 'have capitalized first name' do
      assert_equal 'Jimmy', @user.first_name
    end

  end

  context 'reservations' do
    should 'find rejected reservations' do
      @user = FactoryGirl.create(:user, :reservations => [
        FactoryGirl.create(:reservation, :state => 'unconfirmed'),
        FactoryGirl.create(:reservation, :state => 'rejected')
      ])
      assert_equal 1, @user.rejected_reservations.count
    end

    should 'find confirmed reservations' do
      @user = FactoryGirl.create(:user, :reservations => [
        FactoryGirl.create(:reservation, :state => 'unconfirmed'),
        FactoryGirl.create(:reservation, :state => 'confirmed')
      ])
      assert_equal 1, @user.confirmed_reservations.count
    end

    should 'find expired reservations' do
      @user = FactoryGirl.create(:user, :reservations => [
        FactoryGirl.create(:reservation, :state => 'unconfirmed'),
        FactoryGirl.create(:reservation, :state => 'expired')
      ])
      assert_equal 1, @user.expired_reservations.count
    end

    should 'find cancelled reservations' do
      @user = FactoryGirl.create(:user, :reservations => [
        FactoryGirl.create(:reservation, :state => 'unconfirmed'),
        FactoryGirl.create(:reservation, :state => 'cancelled_by_guest'),
        FactoryGirl.create(:reservation, :state => 'cancelled_by_host')
      ])
      assert_equal 2, @user.cancelled_reservations.count
    end
  end

  should "have authentications" do
    @user = FactoryGirl.create(:user)
    @user.authentications << FactoryGirl.build(:authentication)
    @user.authentications << FactoryGirl.build(:authentication_linkedin)
    @user.save

    assert @user.reload.authentications

    assert_nil @user.facebook_url
    assert_equal 'http://twitter.com/someone', @user.twitter_url
    assert_equal 'http://linkedin.com/someone', @user.linkedin_url
    assert_nil @user.instagram_url
  end

  should "be valid even if its company is not valid" do
    @user = FactoryGirl.create(:user)
    @company = FactoryGirl.create(:company, :creator => @user)
    @company.name = nil
    @company.save(:validate => false)
    @user.reload
    assert @user.valid?
  end

  should "know what authentication providers it is linked to" do
    @user = FactoryGirl.create(:user)
    @user.authentications.find_or_create_by_provider("exists").tap do |a|
      a.uid = @user.id
      a.token = "abcd"
    end.save!
    assert @user.linked_to?("exists")
  end

  should "know what authentication providers it isn't linked to" do
    @user = FactoryGirl.create(:user)
    refute @user.linked_to?("doesntexist")
  end

  should "it has reservations" do
    @user = User.new
    @user.reservations << Reservation.new
    @user.reservations << Reservation.new

    assert @user.reservations
  end

  should "have full email address" do
    @user = User.new(name: "Hulk Hogan", email: "hulk@desksnear.me")

    assert_equal "Hulk Hogan <hulk@desksnear.me>", @user.full_email
  end

  should "not have avatar if user did not upload it" do
    @user = FactoryGirl.create(:user)
    @user.remove_avatar!
    @user.save!

    assert !@user.avatar.any_url_exists?
  end

  should "have avatar if user uploaded it" do
    @user = FactoryGirl.build(:user)
    @user.avatar = File.open(File.expand_path("../../assets/foobear.jpeg", __FILE__))
    @user.avatar_versions_generated_at = Time.zone.now
    @user.save!
    assert @user.avatar.any_url_exists?
  end

  should "allow to download image from linkedin which do not have extension" do
    @user = FactoryGirl.build(:user)
    @user.avatar = File.open(File.expand_path("../../assets/image_no_extension", __FILE__))
    @user.avatar_versions_generated_at = Time.zone.now
    assert @user.save
  end

  should "have mailer unsubscriptions" do
    @user = FactoryGirl.create(:user)
    @user.unsubscribe('recurring_mailer/analytics')

    assert @user.unsubscribed?('recurring_mailer/analytics')
  end

  context '#full_mobile_number' do
    setup do
      @nz = Country.find('New Zealand')
    end

    should 'prefix with international calling code' do
      user = User.new
      user.country_name = @nz.name
      user.mobile_number = '123456'
      assert_equal '+64123456', user.full_mobile_number
    end

    should 'not include 0 prefix from base number' do
      user = User.new
      user.country_name = @nz.name
      user.mobile_number = '0123456'
      assert_equal '+64123456', user.full_mobile_number
    end
  end

  context "#has_phone_and_country?" do
    context "phone and country are present" do
      should "return true" do
        user = User.new
        user.country_name = "United States"
        user.phone = "1234"
        assert user.has_phone_and_country?
      end
    end

    context "phone is missing" do
      should "return false" do
        user = User.new
        user.country_name = "United States"
        assert_equal user.has_phone_and_country?, false
      end
    end

    context "phone is missing" do
      should "return true" do
        user = User.new
        user.phone = "1234"
        assert_equal user.has_phone_and_country?, false
      end
    end
  end

  context "#phone_or_country_was_changed?" do
    context "previous value was blank" do
      context "phone was changed" do
        should "return true" do
          user = User.new
          user.phone = 456
          assert user.phone_or_country_was_changed?
        end
      end

      context "country_name was changed" do
        should "return true" do
          user = User.new
          user.country_name = "Slovenia"
          assert user.phone_or_country_was_changed?
        end
      end
    end

    context "previous value wasn't blank" do
      context "phone was changed" do
        should "return false" do
          user = FactoryGirl.create(:user)
          user.phone = 456
          assert !user.phone_or_country_was_changed?
        end
      end

      context "country_name was changed" do
        should "return false" do

          user = FactoryGirl.create(:user)

          user.country_name = "Slovenia"
          assert !user.phone_or_country_was_changed?
        end
      end
    end

    context 'full_mobile_number_updated?' do

      should 'be true if mobile phone was updated' do
        user = FactoryGirl.create(:user)
        user.mobile_number = "31232132"
        assert user.full_mobile_number_updated?
      end

      should 'be true if country was updated' do
        user = FactoryGirl.create(:user)
        user.country_name = "Poland"
        assert user.full_mobile_number_updated?
      end

      should 'be false if phone was updated' do
        user = FactoryGirl.create(:user)
        user.phone = "31232132"
        assert !user.full_mobile_number_updated?
      end

    end

    context "update_notified_mobile_number_flag" do

      setup do
        @user = FactoryGirl.create(:user)
        @user.notified_about_mobile_number_issue_at = Time.zone.now
      end

      should "be false if phone or country has changed" do
        @user.stubs(:full_mobile_number_updated?).returns(true)
        @user.save!
        assert_nil @user.notified_about_mobile_number_issue_at
      end

      should "not update timestamp when saved" do
        Timecop.freeze(Time.zone.now)
        @user.stubs(:full_mobile_number_updated?).returns(false)
        notified_at = Time.zone.now - 5.days
        @user.notified_about_mobile_number_issue_at = notified_at
        @user.save!
        assert_equal notified_at, @user.notified_about_mobile_number_issue_at
        Timecop.return
      end
    end
  end

  context "notify about invalid mobile phone" do

    setup do
      stub_mixpanel
      FactoryGirl.create(:instance)
      @user = FactoryGirl.create(:user)
    end

    should 'notify user about invalid phone via email' do
      PlatformContext.any_instance.stubs(:domain).returns(FactoryGirl.create(:domain, :name => 'custom.domain.com'))
      @user.notify_about_wrong_phone_number
      sent_mail = ActionMailer::Base.deliveries.last
      assert_equal [@user.email], sent_mail.to

      assert sent_mail.html_part.body.encoded.include?('1.888.998.3375'), "Body did not include expected phone number 1.888.998.3375"
      assert sent_mail.html_part.body.encoded =~ /<a class="btn" href="http:\/\/custom.domain.com\/users\/edit\?token=.+" style=".+">Go to My account<\/a>/, "Body did not include expected link to edit profile in #{sent_mail.html_part.body}"
    end

    should 'not spam user' do
      UserMailer.expects(:notify_about_wrong_phone_number).returns(mailer_stub).once
      5.times do
        @user.notify_about_wrong_phone_number
      end
    end

    should 'update timestamp of notification' do
      UserMailer.expects(:notify_about_wrong_phone_number).returns(mailer_stub).once
      Timecop.freeze(Time.zone.now)
      @user.notify_about_wrong_phone_number
      assert_equal Time.zone.now.to_a, @user.notified_about_mobile_number_issue_at.to_a
    end

  end


  context "mailchimp" do

    should "not be exported without synchronize timestamp" do
      @user = FactoryGirl.create(:user)
      assert !@user.mailchimp_exported?
    end

    should "not exported with synchronize timestamp" do
      @user = FactoryGirl.create(:user)
      @user.mailchimp_synchronized_at = Time.zone.now
      assert @user.mailchimp_exported?
    end

    context "synchronize" do

      setup do
        @user = FactoryGirl.create(:user)
        @user.mailchimp_synchronized!
      end

      teardown do
        Timecop.return
      end

      context "user CRUD" do

        should "be synchronized if no change happened since last synchronize" do
          assert @user.mailchimp_synchronized?
        end

        should "not be synchronized if change to user happened since last synchronize" do
          Timecop.travel(Time.zone.now+10.seconds)
          @user.name = 'John Smith'
          @user.save!
          assert !@user.mailchimp_synchronized?
        end

        should "be synchronized if multiple changes happens to user but none after last synchronize" do
          Timecop.travel(Time.zone.now+10.seconds)
          @user.name = 'John Smith'
          @user.save!
          Timecop.travel(Time.zone.now+10.seconds)
          @user.mailchimp_synchronized!
          assert @user.mailchimp_synchronized?
        end
      end
    end

    context "has listing without price" do

      setup do
        @user = FactoryGirl.create(:user, :name => 'John Smith')
        @company = FactoryGirl.create(:company, :creator => @user)
        @location = FactoryGirl.create(:location, :company => @company)
        @location2 = FactoryGirl.create(:location, :company => @company)
        FactoryGirl.create(:transactable, :location => @location, :daily_price_cents => 10)
        FactoryGirl.create(:transactable, :location => @location, :daily_price_cents => 20)
      end

      should "has listing without price return false if all listings have price" do
        assert !@user.reload.has_listing_without_price?
      end

      should "be false if location has only one listing without prices" do
        FactoryGirl.create(:transactable, :location => @location2, :daily_price_cents => nil, :weekly_price_cents => nil, :monthly_price_cents => nil, :free => true)
        assert @user.reload.has_listing_without_price?
      end

      should "be false if location has many listing, and at least one is without price" do
        FactoryGirl.create(:transactable, :location => @location, :daily_price_cents => nil, :weekly_price_cents => nil, :monthly_price_cents => nil, :free => true)
        assert @user.reload.has_listing_without_price?
      end

    end

  end

  context 'no orphaned childs' do

    context 'user is the only owner of company' do

      should 'destroy company' do
        @listing = FactoryGirl.create(:transactable)
        @location = @listing.location
        @company = @location.company
        @company.add_creator_to_company_users
        @company.save!
        @listing.creator.destroy
        assert @listing.reload.deleted?
        assert @location.reload.deleted?
        assert @company.reload.deleted?
      end

    end

    context 'company has multiple administrators' do

      setup do
        @listing = FactoryGirl.create(:transactable)
        @user = @listing.creator
        @company = @listing.company
        @company.add_creator_to_company_users
        @company.save!
        @new_user = FactoryGirl.create(:user)
        CompanyUser.create(:user_id => @new_user.id, :company_id => @listing.company.id)
      end

      should 'not delete company and assign new creator' do
        @listing.creator.destroy
        @listing.reload
        assert_equal @new_user, @listing.creator
        refute @listing.deleted?
        refute @listing.location.deleted?
        refute @listing.location.company.deleted?
      end

      should 'not destroy company' do
        @new_user.destroy
        @listing.reload
        assert_equal @user, @listing.reload.creator
        refute @listing.deleted?
        refute @listing.location.deleted?
        refute @listing.location.company.deleted?
      end

    end

    should 'nullify administrator_id if user is administrator' do
      @user = FactoryGirl.create(:user)
      @location = FactoryGirl.create(:location, :creator => FactoryGirl.create(:user), :administrator => @user)
      CompanyUser.create(:user_id => @user.id, :company_id => @location.company.id)
      assert @location.administrator_id = @user.id
      @user.destroy
      assert_nil @location.reload.administrator_id
    end

  end


  context '#listings_in_near' do

    setup do
      @user = FactoryGirl.create(:user)
      @other_instance = FactoryGirl.create(:instance)
    end

    should 'return empty array if no platform_context set' do
      assert_equal @user.listings_in_near, []
    end

    should 'return listings from current platform_context instance' do
      # user was last geolocated in Auckland
      @user.last_geolocated_location_latitude = -36.858675
      @user.last_geolocated_location_longitude = 174.777303
      @user.save

      listing_current_instance = FactoryGirl.create(:listing_in_auckland)

      listing_other_instance = FactoryGirl.create(:listing_in_auckland)
      listing_other_instance.update_attribute(:instance_id, @other_instance.id)

      assert_equal [listing_current_instance], @user.listings_in_near
    end

    should 'not return listings from cancelled/expired/rejected reservations' do
      # user was last geolocated in Auckland
      @user.last_geolocated_location_latitude = -36.858675
      @user.last_geolocated_location_longitude = 174.777303
      @user.save
      listing_first = FactoryGirl.create(:listing_in_auckland)
      listing_second = FactoryGirl.create(:listing_in_auckland)
      reservation = FactoryGirl.create(:reservation, listing: listing_first, user: @user)
      reservation.reject
      assert_equal [listing_second], @user.listings_in_near(3, 100, true)
    end
  end

  context 'recovering user with all objects' do

    setup do
      @industry = FactoryGirl.create(:industry)
    end

    should 'recover all objects' do
      setup_user_with_all_objects
      @user.destroy
      @objects.each do |object|
        assert object.reload.destroyed?, "#{object.class.name} was expected to be deleted via dependent => destroy but wasn't"
      end
      @user.restore(:recursive => true)
      @objects.each do |object|
        refute object.reload.destroyed?, "#{object.class.name} was expected to be restored, but is still deleted"
      end
    end

  end

  context 'accepts sms' do

    setup do
      @user = FactoryGirl.create(:user)
    end

    should 'not accept sms if no mobile phone' do
      @user.mobile_number = nil
      refute @user.accepts_sms?
    end

    should 'not accept sms if sms notifications are not enabled' do
      @user.sms_notifications_enabled = false
      refute @user.accepts_sms?
    end

    should 'not accept sms with specific type if this type of sms is disabled by user' do
      @user.sms_preferences = {}
      refute @user.accepts_sms_with_type?(:new_reservation)
    end

    should 'accept sms with specific type if this type of sms is enabled by user' do
      @user.sms_preferences = {"new_reservation" => '1'}
      assert @user.accepts_sms_with_type?(:new_reservation)
    end

  end

  context 'metadata' do


    context 'listings_metadata' do

      setup do
        @listing = FactoryGirl.create(:transactable)
        @user = @listing.creator
      end

      should 'have active listing and no draft listing if has only one active listing metadata' do
        @user.expects(:update_metadata).with({
          has_draft_listings: false,
          has_any_active_listings: true
        })
        @user.populate_listings_metadata!
      end

      should 'have active listing and draft listing if there are both draft and active listing' do
        FactoryGirl.create(:transactable, :draft => Time.zone.now, :location => @listing.location)
        @user.expects(:update_metadata).with({
          has_draft_listings: true,
          has_any_active_listings: true
        })
        @user.populate_listings_metadata!
      end

      should 'have only draft listing if there is only draft listing, but should respond to update' do
        @listing.update_column(:draft, Time.zone.now)
        @user.expects(:update_metadata).with({
          has_draft_listings: true,
          has_any_active_listings: false
        })
        @user.populate_listings_metadata!
        @listing.update_column(:draft, nil)
        @user.expects(:update_metadata).with({
          has_draft_listings: false,
          has_any_active_listings: true
        })
        @user.populate_listings_metadata!
      end

      should 'have no draft and no active listings if there is no listing at all' do
        @listing.destroy
        @user.expects(:update_metadata).with({
          has_draft_listings: false,
          has_any_active_listings: false
        })
        @user.populate_listings_metadata!
      end
    end

    context 'populate_companies_metadata' do

      setup do
        @listing = FactoryGirl.create(:transactable)
        @user = @listing.creator
      end

      should 'have no active listing if company is assigned to someone else and have active listing if assigned back' do
        @company = @listing.company
        @listing.company.company_users.first.destroy
        @user.expects(:update_metadata).with({
          companies_metadata: [],
          has_draft_listings: false,
          has_any_active_listings: false
        })
        @user.reload.populate_companies_metadata!
        @listing.company.company_users.create(:user_id => @user.id)
        @user.expects(:update_metadata).with({
          companies_metadata: [@company.id],
          has_draft_listings: false,
          has_any_active_listings: true
        })
        @user.reload.populate_companies_metadata!
      end

    end

    context 'populate_instance_admins_metadata' do

      setup do
        @instance_admin = FactoryGirl.create(:instance_admin)
        @user = @instance_admin.user
      end

      should 'populate correct instance_admin hash across instances' do
        PlatformContext.current = PlatformContext.new(FactoryGirl.create(:instance))
        @random_instance_admin = FactoryGirl.create(:instance_admin)
        PlatformContext.current = PlatformContext.new(FactoryGirl.create(:instance))
        @other_instance_admin = FactoryGirl.create(:instance_admin, user: @user)
        @user.expects(:update_metadata).with({
          :instance_admins_metadata => {
            "#{@instance_admin.instance_id}" => 'analytics',
            "#{@other_instance_admin.instance_id}" => 'analytics'
          }
        })
        @user.populate_instance_admins_metadata!
      end

    end
  end

  private

  def setup_user_with_all_objects
    @user = FactoryGirl.create(:user)
    @user_industry = UserIndustry.create(:user_id => @user.id, :industry_id => @industry.id)
    @authentication = FactoryGirl.create(:authentication, :user => @user)
    @company = FactoryGirl.create(:company, :creator => @user)
    @company_industry = CompanyIndustry.where(:company_id => @company.id).first
    @location = FactoryGirl.create(:location, :company_id => @company.id)
    @listing = FactoryGirl.create(:transactable, :location => @location)
    @photo  = FactoryGirl.create(:photo, :listing => @listing, :creator => @photo)
    @reservation = FactoryGirl.create(:reservation, :user => @user, :listing => @listing)
    @reservation_period = @reservation.periods.first
    @reservation_charge = FactoryGirl.create(:reservation_charge, :reservation => @reservation)
    @charge = FactoryGirl.create(:charge, :reference => @reservation_charge)
    @payment_transfer = FactoryGirl.create(:payment_transfer, :company_id => @company.id)
    @objects = [@user, @user_industry, @authentication, @company, @company_industry,
                @location, @listing, @photo, @reservation, @reservation_period,
                @payment_transfer, @reservation_charge, @charge]
  end

end

