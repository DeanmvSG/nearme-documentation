require 'test_helper'

class ListingsHelperTest < ActionView::TestCase
  include ListingsHelper

  context '#space_listing_placeholder_url' do
    should "return valid placeholder" do
      expected_url = "http://placehold.it/100x200&text=Photos+Unavailable"
      assert_equal expected_url, space_listing_placeholder_url(width: 100, height: 200)
    end
  end
end
