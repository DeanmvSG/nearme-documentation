require 'test_helper'
require 'helpers/search_params_test_helper'
class Listing::Search::ParamsTest <  ActiveSupport::TestCase
  include SearchParamsTestHelper

  context "#query" do
    context "when coordinates are not provided" do
      should "keep the query when created with a query that is not found" do
        assert_equal "not_found_location", build_params(options_with_query("not_found_location"), fake_geocoder(false)).query
      end

      should "remove the query when created with a query that was found" do
        assert_equal nil, build_params(options_with_query, fake_geocoder(true)).query
      end
    end
    context "when coordinates are provided" do
      should "keeps the query if the query is not found" do
        assert_equal "not_found_location", build_params(options_with_midpoint.merge(options_with_query("not_found_location")), fake_geocoder(false)).query
      end
    end
  end

  context '#keyword_search?' do
    should "return true if there is a query" do
      params = build_params(options_with_midpoint(options_with_query), fake_geocoder(true))
      assert params.query.present?
      assert params.keyword_search?
    end

    should "return false if there is no query" do
      params = build_params(options_with_midpoint(options_with_query(nil)), fake_geocoder(false))
      assert params.query.blank?
      assert !params.keyword_search?
    end
  end

  context "#to_scope" do
    should "never include deleted items" do
      scope = scope_for(options_with_query, fake_geocoder(false))
      assert_equal scope[:with][:deleted_at], 0
    end

    should "always includes an organization id of 0" do
      scope = scope_for(options_with_query, fake_geocoder(false))
      assert_equal scope[:with][:organization_ids], [0]
    end

    context "when a user is provided" do
      should "includes the organization ids in the with section" do
        options = { query: "asdf", user: Struct.new(:organization_ids).new([1,2,3]) }
        scope = scope_for(options, fake_geocoder(false))
        assert_equal scope[:with][:organization_ids], [1,2,3,0]
      end
    end

    context "when a query is found" do
      should "gives the locations radians to the geo section"  do
        scope = scope_for(options_with_query, fake_geocoder(search_area))
        assert_equal scope[:geo], midpoint.radians
      end

      should "gives the radius to the with section" do
        scope = scope_for(options_with_query, fake_geocoder(search_area))
        assert_equal scope[:with]["@geodist"], 0.0...5.0
      end
      context "and a midpoint is provided" do
        should "should not trigger the geocoder" do
          scope = scope_for(options_with_midpoint.merge(options_with_query("found_location")), fake_geocoder_never_used)
          assert true # expectation
        end
      end

      context "and a bounding box is provided" do
        should "should not trigger the geocoder" do
          scope = scope_for(options_with_bounding_box.merge(options_with_query("found_location")), fake_geocoder_never_used)
          assert true # expectation
        end
      end
    end

    context "when a query is not found" do
      should "does not include the @geodist in with" do
        scope = scope_for(options_with_query, fake_geocoder(false))
        refute scope[:with].has_key? "@geodist"
      end

      should "does not set the geo value" do
        scope = scope_for(options_with_query, fake_geocoder(false))
        refute scope.has_key? :geo
      end
    end

    context "when a center is provided" do
      should "gives the midpoints radians to the geo section" do
        scope = scope_for(options_with_midpoint, fake_geocoder(false))
        assert_equal scope[:geo], midpoint.radians
      end
      should "gives the radius to the with section" do
        scope = scope_for(options_with_midpoint, fake_geocoder(false))
        assert_equal scope[:with]["@geodist"], 0.0...15_000.0
      end
    end

    context "when a boundingbox is provided" do
      should "gives the midpoints radians to the geo section" do
        scope = scope_for(options_with_bounding_box, fake_geocoder(false))
        assert_equal [0.25151695675404967, 0.06546623544501572], scope[:geo]
      end

      should "gives the radius to the with section" do
        scope = scope_for(options_with_bounding_box, fake_geocoder(false))
        assert_equal 0.0...977008.5143096122, scope[:with]["@geodist"]
      end
    end
  end

  def build_params(options, geocoder)
    Listing::Search::Params.new(options, geocoder)
  end
end
