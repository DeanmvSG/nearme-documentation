require 'test_helper'

class SpaceWizardControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  setup do
    @user = FactoryGirl.create(:user)
    @industry = FactoryGirl.create(:industry)
    sign_in @user
    FactoryGirl.create(:listing_type)
    FactoryGirl.create(:location_type)
  end

  context "price must be formatted" do

    should "handle nil and empty prices" do
      assert_difference('Listing.count', 1) do
        post :submit_listing, get_params(nil, "", "249.00")
      end
      @listing = Listing.last
      assert_nil @listing.daily_price
      assert_nil @listing.weekly_price
      assert_equal 24900, @listing.monthly_price_cents
    end

    should "not raise exception if hash is incomplete" do
      assert_no_difference('Listing.count') do
        post :submit_listing, { "company"=> { "name"=>"International Secret Intelligence Service" } }  
      end
    end

  end

  private

  def get_params(daily_price = nil, weekly_price = nil, monthly_price = nil)
        {"company"=>
          {
            "name"=>"International Secret Intelligence Service", 
            "industry_ids"=>["#{@industry.id}"], 
            "locations_attributes"=>
              {"0"=>
                {"description"=>"Our historic 11-story Southern Pacific Building, also known as \"The Landmark\", was completed in 1916. We are in the 172 m Spear Tower.", 
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
                       "listing_type_id"=>"1", 
                       "quantity"=>"1", 
                       "daily_price"=>daily_price, 
                       "weekly_price"=>weekly_price, 
                       "monthly_price"=> monthly_price, 
                       "free"=>"0", 
                       "confirm_reservations"=>"0"}
                    }, 
                 "currency"=>"USD"}
              }
          }
        }
  end

end

