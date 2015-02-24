require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  setup do
    stub_request(:get, /.*maps\.googleapis\.com.*/)
    stub_mixpanel
    PlatformContext.current = PlatformContext.new(Instance.first)
  end

  context 'for transactable type listing' do
    setup do
      FactoryGirl.create(:transactable_type_listing)
    end

    context 'search integration' do
      setup do
        Location.destroy_all
      end

      context 'for disabled listing' do
        should 'exclude disabled listing' do
          location = @auckland = FactoryGirl.create(:location_in_auckland)
          location.listings.each do |listing|
            listing.update_attribute(:enabled, false)
          end

          get :index, loc: 'Auckland'
          assert_nothing_found
        end
      end

      context 'for invalid place' do
        should 'find nothing for empty query' do
          get :index, loc: ''
          assert_nothing_found
        end

        should 'find nothing for invalid query' do
          get :index, loc: 'bung'
          assert_nothing_found
        end
      end

      context 'for unavailable listings' do
        should 'display also unavailable listings' do
          unavaliable_location = FactoryGirl.create(:fully_booked_listing_in_cleveland).location
          available_location = FactoryGirl.create(:listing_in_cleveland).location

          get :index, loc: 'Cleveland', v: 'mixed'

          assert_location_in_mixed_result(unavaliable_location)
          assert_location_in_mixed_result(available_location)
        end
      end

      context 'for existing location' do
        context 'with industry filter' do
          should 'filter only filtered locations' do
            filtered_industry = FactoryGirl.create(:industry)
            another_industry = FactoryGirl.create(:industry)
            filtered_auckland = FactoryGirl.create(:company, industries: [filtered_industry], locations: [FactoryGirl.create(:location_in_auckland)]).locations.first
            another_auckland = FactoryGirl.create(:company, industries: [another_industry], locations: [FactoryGirl.create(:location_in_auckland)]).locations.first

            get :index, { loc: 'Auckland', industries_ids: [filtered_industry.id], v: 'list' }

            assert_location_in_result(filtered_auckland)
            refute_location_in_result(another_auckland)
          end
        end

        context 'with location type filter' do
          should 'filter only filtered locations' do
            filtered_location_type = FactoryGirl.create(:location_type)
            another_location_type = FactoryGirl.create(:location_type)
            filtered_auckland = FactoryGirl.create(:location_in_auckland, location_type: filtered_location_type)
            another_auckland = FactoryGirl.create(:location_in_auckland, location_type: another_location_type)

            get :index, { loc: 'Auckland', lntype: filtered_location_type.name.downcase, v: 'mixed' }

            assert_location_in_result(filtered_auckland)
            refute_location_in_result(another_auckland)
          end
        end

        context 'with listing type filter' do
          should 'filter only filtered locations' do
            filtered_listing_type = "Desk"
            another_listing_type = "Meeting Room"
            filtered_auckland = FactoryGirl.create(:listing_in_auckland, listing_type: filtered_listing_type).location
            another_auckland = FactoryGirl.create(:listing_in_auckland, listing_type: another_listing_type).location

            get :index, { loc: 'Auckland', lgtype: filtered_listing_type, v: 'mixed' }

            assert_location_in_mixed_result(filtered_auckland)
            refute_location_in_mixed_result(another_auckland)
          end
        end

        context 'with attribute value filter' do
          should 'filter only filtered locations' do
            FactoryGirl.create(:custom_attribute, target: TransactableType.first, attribute_type: 'string', name: 'filterable_attribute')
            listing = FactoryGirl.create(:listing_in_cleveland, photos_count: 1)
            listing.properties[:filterable_attribute] = 'Lefthanded'
            listing.properties_will_change!
            listing.save!
            filtered_auckland = listing.location
            another_auckland = FactoryGirl.create(:listing_in_cleveland).location

            get :index, { loc: 'Cleveland', lgattribute: 'Lefthanded', v: 'mixed' }

            assert_location_in_mixed_result(filtered_auckland)
            refute_location_in_mixed_result(another_auckland)
          end
        end

        context 'without filter' do
          context 'show only valid locations' do
            setup do
              @auckland = FactoryGirl.create(:location_in_auckland)
              @adelaide = FactoryGirl.create(:location_in_adelaide)
            end

            should 'in map view' do
              get :index, loc: 'Adelaide', v: 'map'
              assert_location_in_result(@adelaide)
              refute_location_in_result(@auckland)
            end

            should 'in mixed view' do
              get :index, loc: 'Adelaide', v: 'mixed'
              assert_location_in_result(@adelaide)
              refute_location_in_result(@auckland)
            end

            context 'in list view' do

              should 'show results' do
                get :index, loc: 'Adelaide', v: 'list'
                assert_location_in_result(@adelaide)
                refute_location_in_result(@auckland)
              end

              context 'connections' do
                setup do
                  @me = FactoryGirl.create(:user)
                  @friend = FactoryGirl.create(:user)
                  @me.add_friend(@friend)

                  FactoryGirl.create(:past_reservation, listing: FactoryGirl.create(:transactable, location: @adelaide), user: @friend, state: 'confirmed')
                end

                should 'are shown for logged user' do
                  sign_in(@me)
                  @me.stubs(:unread_messages_count).returns(0)

                  get :index, loc: 'Adelaide', v: 'list'

                  assert_select '.connections[rel=?]', 'tooltip', 1
                  assert_select '[title=?]', "#{@friend.name} worked here"
                end

                should 'are hidden for guests' do
                  sign_out(@me)

                  get :index, loc: 'Adelaide', v: 'list'

                  assert_select '.connections[rel=?]', 'tooltip', 0
                end
              end
            end
          end
        end
      end
    end

    context 'conduct search' do


      should "not track search for empty query" do
        @tracker.expects(:conducted_a_search).never
        get :index, loc: nil
      end

      should 'track search for first page' do
        @tracker.expects(:conducted_a_search).once
        get :index, loc: 'adelaide', page: 1
      end

      should 'not track search for second page' do
        @tracker.expects(:conducted_a_search).never
        get :index, loc: 'adelaide', page: 2
      end

      should 'log filters in mixpanel along with other arguments for list result type' do
        @listing_type = "Meeting Room"
        @location_type = FactoryGirl.create(:location_type)
        @industry = FactoryGirl.create(:industry)
        expected_custom_options = {
          search_query: 'adelaide',
          result_view: 'list',
          result_count: 0,
          listing_type_filter: [@listing_type],
          location_type_filter: [@location_type.name],
          industry_filter: [@industry.name],
          attribute_filter: ['Lefthanded']
        }
        @tracker.expects(:conducted_a_search).with do |search, custom_options|
          expected_custom_options == custom_options
        end
        get :index, { loc: 'adelaide', attribute_values: ['Lefthanded'], listing_types_ids: [@listing_type], location_types_ids: [@location_type.id], industries_ids: [@industry.id], v: 'list' }
      end

      should 'log filters in mixpanel along with other arguments for mixed result type' do
        @listing_type = "Desk"
        @location_type = FactoryGirl.create(:location_type)
        expected_custom_options = {
          search_query: 'adelaide',
          result_view: 'mixed',
          result_count: 0,
          listing_type_filter: [@listing_type],
          location_type_filter: [@location_type.name],
          listing_pricing_filter: ['daily'],
          attribute_filter: ['Lefthanded']
        }
        @tracker.expects(:conducted_a_search).with do |search, custom_options|
          expected_custom_options == custom_options
        end
        get :index, { loc: 'adelaide', lgtype: @listing_type, lntype: @location_type.name.downcase, lgpricing: 'daily', lgattribute: 'Lefthanded', v: 'mixed' }
      end

      should 'track search if ignore_search flag is set to 0' do
        @tracker.expects(:conducted_a_search).once
        get :index, loc: 'adelaide', ignore_search_event: "0"
      end

      should 'not track search if ignore_search flag is set to 1' do
        @tracker.expects(:conducted_a_search).never
        get :index, loc: 'adelaide', ignore_search_event: "1"
      end

      should 'not track second search for the same query if filters have not been changed' do
        @tracker.expects(:conducted_a_search).once
        get :index, loc: 'adelaide'
        get :index, loc: 'adelaide'
      end

      context 'modified filters' do

        setup do
          @tracker.expects(:conducted_a_search).twice
          get :index, loc: 'adelaide'
          @controller.instance_variable_set(:@search, nil)
        end

        should 'track search if listing filter has been modified' do
          get :index, loc: 'adelaide', lgtype: "Some Filter"
        end

        should 'track search if location filter has been modified' do
          get :index, loc: 'adelaide', lntype: FactoryGirl.create(:location_type).name.downcase
        end

        should 'track search if industry filter has been modified' do
          get :index, loc: 'adelaide', industries_ids: [FactoryGirl.create(:industry).id], v: 'list'
        end

        should 'track search if listing pricing filter has been modified' do
          get :index, loc: 'adelaide', lgpricing: 'daily'
        end

      end

      should 'not track second search for the different query' do
        @tracker.expects(:conducted_a_search).twice
        get :index, loc: 'adelaide'
        get :index, loc: 'auckland'
      end

    end
  end

  context 'for transactable type buy/sell' do
    setup do
      FactoryGirl.create(:transactable_type_buy_sell)
    end

    context 'search integration' do
      setup do
        Spree::Product.destroy_all
      end

      context 'for disabled listing' do
        should 'exclude disabled listing' do
          FactoryGirl.create(:product, approved: false, name: 'product')

          get :index, loc: 'product', v: 'products'
          assert_no_products_found
        end
      end

      context 'for invalid place' do
        should 'find nothing for empty query' do
          get :index, loc: '', v: 'products'
          assert_no_products_found
        end

        should 'find nothing for invalid query' do
          get :index, loc: 'bung', v: 'products'
          assert_no_products_found
        end
      end

      context 'for existing products' do
        context 'with taxon filter' do
          should 'filter only filtered products' do
            taxon = FactoryGirl.create(:taxon, name: 'taxon_1')
            another_taxon = FactoryGirl.create(:taxon)
            filtered_product = FactoryGirl.create(:product, taxons: [taxon])
            another_product = FactoryGirl.create(:product, taxons: [another_taxon])

            get :index, { taxon: taxon.permalink, v: 'products' }

            assert_product_in_result(filtered_product)
            refute_product_in_result(another_product)
          end
        end

        context 'without filter' do
          should 'show only valid products' do
            product1 = FactoryGirl.create(:product, name: 'product_one')
            product2 = FactoryGirl.create(:product, name: 'product_two')

            get :index, loc: 'product_one', v: 'products'
            assert_product_in_result(product1)
            refute_product_in_result(product2)
          end
        end
      end
    end

    context 'conduct search' do

      should "not track search for empty query" do
        @tracker.expects(:conducted_a_search).never
        get :index, loc: nil, v: 'products'
      end

      should 'track search for first page' do
        @tracker.expects(:conducted_a_search).once
        get :index, loc: 'product_1', page: 1, v: 'products'
      end

      should 'not track search for second page' do
        @tracker.expects(:conducted_a_search).never
        get :index, loc: 'product_1', page: 2, v: 'products'
      end

      should 'not track second search for the different query' do
        @tracker.expects(:conducted_a_search).twice
        get :index, loc: 'product_1', v: 'products'
        get :index, loc: 'product_2', v: 'products'
      end

      should 'track search if ignore_search flag is set to 0' do
        @tracker.expects(:conducted_a_search).once
        get :index, loc: 'product_1', ignore_search_event: "0", v: 'products'
      end

      should 'not track search if ignore_search flag is set to 1' do
        @tracker.expects(:conducted_a_search).never
        get :index, loc: 'product_1', ignore_search_event: "1", v: 'products'
      end

      should 'not track second search for the same query if filters have not been changed' do
        @tracker.expects(:conducted_a_search).once
        get :index, loc: 'product_1', v: 'products'
        get :index, loc: 'product_1', v: 'products'
      end

      should 'log filters in mixpanel along with other arguments for products result type' do
        expected_custom_options = {
          search_query: 'product_1',
          result_view: 'products',
          result_count: 0,
          attribute_filter: ['Lefthanded']
        }
        @tracker.expects(:conducted_a_search).with do |search, custom_options|
          expected_custom_options == custom_options
        end
        get :index, { loc: 'product_1', attribute_values: ['Lefthanded'], v: 'products' }
      end
    end
  end

  protected

  def assert_nothing_found
    assert_select 'h1', 1, 'No results found'
    assert_select 'p', 1, "The address you entered couldn't be found"
  end

  def assert_no_products_found
    assert_select 'h1', 1, 'No results found'
  end

  def assert_location_in_result(location)
    location.listings.each do |listing|
      assert_select 'article[data-id=?]', listing.id, count: 1
    end
  end

  def refute_location_in_result(location)
    location.listings.each do |listing|
      assert_select 'article[data-id=?]', listing.id, count: 0
    end
  end

  def assert_location_in_mixed_result(location)
    assert_select 'article[data-id=?]', location.id, count: 1
  end

  def refute_location_in_mixed_result(location)
    assert_select 'article[data-id=?]', location.id, count: 0
  end

  def assert_product_in_result(product)
    assert_select '.result-item[data-product-id=?]', product.id, count: 1
  end

  def refute_product_in_result(product)
    assert_select '.result-item[data-product-id=?]', product.id, count: 0
  end


end

