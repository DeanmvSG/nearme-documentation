require 'test_helper'
require 'vcr_setup'

class SpaceWizardControllerTest < ActionController::TestCase

  setup do
    @user = FactoryGirl.create(:user)
    @instance = FactoryGirl.create(:instance)
    @industry = FactoryGirl.create(:industry)
    sign_in @user
    FactoryGirl.create(:listing_type)
    FactoryGirl.create(:location_type)
    @partner = FactoryGirl.create(:partner)
    stub_mixpanel
  end

  context 'scopes current partner for new company' do
    should 'match partner_id' do
      PlatformContext.any_instance.stubs(:partner).returns(@partner)
      assert_difference('Listing.count', 1) do
        post :submit_listing, get_params
      end
      @company = Company.last
      assert_equal @partner.id, @company.partner_id
    end
  end

  context "price must be formatted" do

    should "ignore invalid characters in price" do
      assert_difference('Listing.count', 1) do
        post :submit_listing, get_params("249.31-300.00", '!@#$%^&*()_+=_:;"[]}{\,<.>/?`~', 'i am not valid price I guess', "0")
      end
      @listing = assigns(:listing)
      assert_equal 24931, @listing.daily_price_cents
      assert_equal 0, @listing.weekly_price_cents
      assert_equal 0, @listing.monthly_price_cents
    end

    should "handle nil and empty prices" do
      assert_difference('Listing.count', 1) do
        post :submit_listing, get_params(nil, "", "249.00", "0")
      end
      @listing = assigns(:listing)
      assert_nil @listing.daily_price
      assert_nil @listing.weekly_price
      assert_equal 24900, @listing.monthly_price_cents
    end

    should "not raise exception if hash is incomplete" do
      assert_no_difference('Listing.count') do
        post :submit_listing, { "user" => {"companies_attributes" => {"0"=> { "name"=>"International Secret Intelligence Service" }}}}
      end
    end


  end

  context "geo-located default country" do
    setup do
      @user.country_name = nil
      @user.save!
    end

    should "be set to Greece" do
      VCR.use_cassette "freegeoip_greece" do
        # Set request ip to an ip address in Greece
        @request.env['REMOTE_ADDR'] = '2.87.255.255'
        get :list
        assert assigns(:country) == "Greece"
        assert_select 'option[value="Greece"][selected="selected"]', 1
      end
    end

    should "be set to Brazil" do
      VCR.use_cassette "freegeoip_brazil" do
        # Set request ip to an ip address in Brazil
        @request.env['REMOTE_ADDR'] = '139.82.255.255'
        get :list
        assert assigns(:country) == "Brazil"
        assert_select 'option[value="Brazil"][selected="selected"]', 1
      end
    end

  end

  context 'track' do
    setup do
      @tracker = Analytics::EventTracker.any_instance
    end

    should "track location and listing creation" do
      @tracker.expects(:created_a_location).with do |location, custom_options|
        location == assigns(:location) && custom_options == { via: 'wizard' }
      end
      @tracker.expects(:created_a_listing).with do |listing, custom_options|
        listing == assigns(:listing) && custom_options == { via: 'wizard' }
      end
      @tracker.expects(:created_a_company).with do |company, custom_options|
        company == assigns(:company)
      end
      @tracker.expects(:updated_profile_information).with do |user|
        user == @user
      end
      post :submit_listing, get_params
    end

    should "track draft creation" do
      @tracker.expects(:saved_a_draft)
      post :submit_listing, get_params.merge({"save_as_draft"=>"Save as draft"})
    end

    should 'track clicked list your bookable when logged in' do
      @tracker.expects(:clicked_list_your_bookable)
      get :new
    end

    should 'track clicked list your bookable when not logged in' do
      sign_out @user
      @tracker.expects(:clicked_list_your_bookable)
      get :new
    end


    should 'track viewed list your bookable' do
      @tracker.expects(:viewed_list_your_bookable)
      get :list
    end

    context '#user has already bookable' do

      setup do
        @listing = FactoryGirl.create(:listing)
        @listing.company.tap { |c| c.creator = @user }.save!
        @listing.company.add_creator_to_company_users
      end

      should 'not track clicked list your bookable if user already has bookable ' do
        @tracker.expects(:clicked_list_your_bookable).never
        get :new
      end

      should 'not track viewed list your bookable if user already has bookable ' do
        @tracker.expects(:viewed_list_your_bookable).never
        get :list

      end

    end

  end

  context 'GET new' do
    should 'redirect to manage location page if has listings' do
      create_listing
      get :new
      assert_redirected_to manage_locations_path
    end

    should 'redirect to space wizard list if no listings' do
      get :new
      assert_redirected_to space_wizard_list_url
    end

    should 'redirect to registration path if not logged in' do
      sign_out @user
      get :new
      assert_redirected_to new_user_registration_url(:wizard => 'space', :return_to => space_wizard_list_path)
    end
  end

  context 'with skip_company' do
    should 'create listing when location skip_company is set to true' do
      @instance_with_skip_company = FactoryGirl.create(:instance, skip_company: true)
      PlatformContext.any_instance.stubs(:instance).returns(@instance_with_skip_company)

      params_without_company_name = get_params
      params_without_company_name['user']['companies_attributes']['0'].delete('name')
      params_without_company_name['user']['companies_attributes']['0'].delete('industry_ids')

      assert_difference('Listing.count', 1) do
        post :submit_listing, params_without_company_name
      end
    end
  end

  private

  def get_params(daily_price = nil, weekly_price = nil, monthly_price = nil, free = "1")
    {"user" =>
     {"companies_attributes"=>
      {"0" =>
       {
         "name"=>"International Secret Intelligence Service", 
         "industry_ids"=>["#{@industry.id}"],
         "locations_attributes"=>
         {"0"=>
          {"description"=>"Our historic 11-story Southern Pacific Building, also known as \"The Landmark\", was completed in 1916. We are in the 172 m Spear Tower.", 
           "name" => 'Location',
           "address"=>"usa", 
           "local_geocoding"=>"10", 
           "latitude"=>"5", 
           "longitude"=>"8", 
           "formatted_address"=>"formatted usa", 
           "location_type_id"=>"1", 
           "listings_attributes"=>
          {"0"=>
           {"name"=>"Desk", 
            "description"=>"We have a group of several shared desks available.",
            "hourly_reservations" => false,
            "listing_type_id"=>"1", 
            "quantity"=>"1", 
            "daily_price"=>daily_price, 
            "weekly_price"=>weekly_price, 
            "monthly_price"=> monthly_price, 
            "free"=>free, 
            "confirm_reservations"=>"0",
            "photos_attributes" => [FactoryGirl.attributes_for(:photo)]}
          }, 
          "currency"=>"USD"}
         }
       },
      },
      "country_name" => "United States",
      "phone" => "123456789"
     }
    }
  end

  def create_listing
    @company = FactoryGirl.create(:company, :creator_id => @user.id)
    @location = FactoryGirl.create(:location)
    @location.listings << FactoryGirl.create(:listing)
    @company.locations << @location
  end

end

