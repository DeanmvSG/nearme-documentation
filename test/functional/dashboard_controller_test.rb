require 'test_helper'

class DashboardControllerTest < ActionController::TestCase

  setup do
    @user = FactoryGirl.create(:user)
    sign_in @user
  end

  context '#analytics' do 

    context '#revenue' do

      setup do
        @listing = FactoryGirl.create(:listing, :quantity => 1000)
        @listing.location.company.tap { |c| c.creator = @user }.save!
        @listing.location.company.add_creator_to_company_users
      end

      context '#assigned variables' do

        context 'ownership' do
          setup do
            @owner_charge = create_reservation_charge(:amount => 100)
            @not_owner_charge = FactoryGirl.create(:charge)
          end

          should '@last_week_reservation_charges ignores charges that do not belong to signed in user' do
            get :analytics
            assert_equal [@owner_charge], assigns(:last_week_reservation_charges)
          end

          should '@reservation_charges ignores charges that do not belong to signed in user' do
            get :analytics
            assert_equal [@owner_charge], assigns(:reservation_charges)
          end

          should '@all_time_totals ' do
            get :analytics
            assert_equal 1, assigns(:all_time_totals).length
          end

          should 'be scoped to current instance' do
            second_instance = FactoryGirl.create(:instance)
            PlatformContext.any_instance.stubs(:instance).returns(second_instance)

            get :analytics
            assert_equal [], assigns(:reservation_charges)
            assert_equal [], assigns(:last_week_reservation_charges)
            assert_equal [], assigns(:all_time_totals)
          end
        end

        context 'date' do 

          setup do
            @charge_created_6_days_ago = create_reservation_charge(:amount => 100, :created_at => Time.zone.now - 6.day)
            @charge_created_7_days_ago = create_reservation_charge(:amount => 100, :created_at => Time.zone.now - 7.day)
          end

          should '@last_week_reservation_charges includes only charges not older than 6 days' do
            get :analytics
            assert_equal [@charge_created_6_days_ago], assigns(:last_week_reservation_charges)
          end

          should '@reservation_charges includes all charges that belong to a user' do
            get :analytics
            assert_equal [@charge_created_6_days_ago, @charge_created_7_days_ago], assigns(:reservation_charges)
          end

        end

      end

    end

    context '#reservations' do
      
      setup do
        @listing = FactoryGirl.create(:listing, :quantity => 1000)
        @listing.location.company.tap { |c| c.creator = @user }.save!
        @listing.location.company.add_creator_to_company_users
      end

      context 'assigned variables' do

        setup do
          @reservation = FactoryGirl.create(:reservation, :currency => 'USD', :listing => @listing) 
        end

        should '@last_week_reservations includes user company reservations' do
          get :analytics, :analytics_mode => 'bookings'
          assert_equal [@reservation], assigns(:reservations)
        end

        should 'be scoped to current instance' do
          second_instance = FactoryGirl.create(:instance)
          PlatformContext.any_instance.stubs(:instance).returns(second_instance)

          get :analytics, :analytics_mode => 'bookings'
          assert_equal [], assigns(:reservations)
        end
      end

      context 'date' do 

        setup do
          @reservation_created_6_days_ago = FactoryGirl.create(:reservation, :currency => 'USD', :listing => @listing, :created_at => Time.zone.now - 6.day)
        end

        should '@last_week_reservations includes only reservations not older than 6 days' do
          get :analytics, :analytics_mode => 'bookings'
          assert_equal [@reservation_created_6_days_ago], assigns(:last_week_reservations)
        end

        should '@last_week is scoped to current instance' do
          second_instance = FactoryGirl.create(:instance)
          PlatformContext.any_instance.stubs(:instance).returns(second_instance)

          get :analytics, :analytics_mode => 'bookings'
          assert_equal [], assigns(:last_week_reservations)
        end

      end

    end


    context '#location_views' do
      
      setup do
        @listing = FactoryGirl.create(:listing, :quantity => 1000)
        @listing.location.company.tap { |c| c.creator = @user }.save!
        @listing.location.company.add_creator_to_company_users
      end


      context 'date' do 

        setup do
          create_location_visit
        end

        should '@last_month_visits has one visit from today' do
          get :analytics, :analytics_mode => 'location_views'
          assert_equal Date.current, Date.strptime(assigns(:last_month_visits).first.impression_date)
          assert_equal 1, assigns(:visits).size
        end

        should '@last_month_visits has no visits from today in second instance' do
          second_instance = FactoryGirl.create(:instance)
          PlatformContext.any_instance.stubs(:instance).returns(second_instance)
          get :analytics, :analytics_mode => 'location_views'
          assert_equal [], assigns(:last_month_visits)
          assert_equal [], assigns(:visits)
        end
      end

    end

  end

  context '#manage_guests' do
    setup do
      @unrelated_listing = FactoryGirl.create(:listing)
      @related_instance = FactoryGirl.create(:instance)
      PlatformContext.any_instance.stubs(:instance).returns(@related_instance)
      @related_company = FactoryGirl.create(:company_in_auckland, :creator_id => @user.id, instance: @related_instance)
      @related_location = FactoryGirl.create(:location_in_auckland, company: @related_company)
      @related_listing = FactoryGirl.create(:listing, location: @related_location)
    end

    context 'is scoped to current instance' do
      should 'show related guests' do
        FactoryGirl.create(:reservation, owner: @user, listing: @related_listing)

        get :manage_guests
        assert_response :success
        assert_select ".reservation-details", 1
      end

      should 'show related locations when no related guests' do
        FactoryGirl.create(:reservation, owner: @user, listing: @unrelated_listing)


        get :manage_guests
        assert_response :success
        assert_select ".reservation-details", 0
        assert_select "h2", @related_location.name
      end
      should 'not show unrelated guests' do
        FactoryGirl.create(:reservation, owner: @user, listing: @unrelated_listing)

        get :manage_guests
        assert_response :success
        assert_select ".reservation-details", 0
      end
    end
  end

  private

  def create_reservation_charge(options = {})
    options.reverse_merge!({:reservation => FactoryGirl.create(:reservation, :currency => 'USD', :listing => @listing)})
    if amount = options.delete(:amount)
      options[:subtotal_amount] = amount
    end

    options[:paid_at] ||= options[:created_at] || Time.zone.now

    FactoryGirl.create(:reservation_charge, options)
  end

  def create_location_visit
    @listing.location.track_impression
  end

end

