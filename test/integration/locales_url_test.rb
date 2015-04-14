require 'test_helper'

class LocalesUrlTest < ActionDispatch::IntegrationTest

  setup do
    RoutingFilter.active = true
    FactoryGirl.create(:default_locale, code: 'en')
  end

  should 'redirect to default language if locale does not exist' do
    get 'http://www.example.com/it/'
    assert_redirected_to 'http://www.example.com/'
  end

  should 'redirect to path without locale for default locale' do
    FactoryGirl.create(:default_locale, code: 'aa')
    get 'http://www.example.com/aa/'
    assert_redirected_to 'http://www.example.com/'
  end

  should 'not redirect for existing locale' do
    FactoryGirl.create(:locale, code: 'fr')
    get 'http://www.example.com/fr/'
    assert_response :success
  end

  should 'throw exception for fantasy locale' do
    assert_raises ActionController::RoutingError do
      get root_path(language: 'xy')
    end
  end

  teardown do
    RoutingFilter.active = false
  end

end
