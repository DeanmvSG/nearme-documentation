ENV["RAILS_ENV"] ||= "test"

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/autorun'
# require 'minitest/reporters'
require 'mocha/setup'
require 'mocha/mini_test'
require 'webmock/minitest'
require 'backtrace_filter'

require Rails.root.join('test', 'helpers', 'stub_helper.rb')

require 'spree/testing_support/factories'

reporter_options = { color: true, slow_count: 5 }
Minitest.backtrace_filter = BacktraceFilter.new
Minitest::Reporters.use!(Minitest::Reporters::DefaultReporter.new(reporter_options), ENV, Minitest.backtrace_filter)

RoutingFilter.active = false
ActiveMerchant::Billing::Base.mode = :test

# Disable carrierwave processing in tests
# It can be enabled on a per-test basis as needed.
CarrierWave.configure do |config|
  config.enable_processing = false
end

module Rack
  module Test
    class UploadedFile
      def tempfile
        @tempfile
      end
    end
  end
end

ActiveSupport::TestCase.class_eval do
  ActiveRecord::Migration.check_pending!

  include FactoryGirl::Syntax::Methods
  include StubHelper

  setup do
    DatabaseCleaner.clean # needed :/
    TestDataSeeder.seed!
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
    PlatformContext.current = PlatformContext.new(Instance.first || FactoryGirl.create(:instance))
  end

  def current_instance
    PlatformContext.current.instance
  end

  def with_versioning
    was_enabled = PaperTrail.enabled?
    PaperTrail.enabled = true
    begin
      yield
    ensure
      PaperTrail.enabled = was_enabled
    end
  end

  def assert_contains(expected, object, message = nil)
    message ||= "Expected #{expected.inspect} to be included in #{object.inspect}"
    assert object.to_s.include?(expected), message
  end

  def assert_not_contains(unexpected, object, message = nil)
    message ||= "Unexpected #{unexpected.inspect} in #{object.inspect}"
    refute object.to_s.include?(unexpected), message
  end

  def with_carrier_wave_processing(&blk)
    before, CarrierWave::Uploader::Base.enable_processing = CarrierWave::Uploader::Base.enable_processing, true
    yield
  ensure
    CarrierWave::Uploader::Base.enable_processing = before
  end

  def raw_post(action, params, body)
    # The problem with doing this is that the JSON sent to the app
    # is that Rails will parse and put the JSON payload into params.
    # But this approach doesn't behave like that for tests.
    # The controllers are doing more work by parsing JSON than necessary.
    @request.env['RAW_POST_DATA'] = body
    response = post(action, params)
    @request.env.delete('RAW_POST_DATA')
    response
  end

  def raw_put(action, params, body)
    @request.env['RAW_POST_DATA'] = body
    response = put(action, params)
    @request.env.delete('RAW_POST_DATA')
    response
  end

  def authenticate!
    @user = FactoryGirl.create(:authenticated_user)
    request.headers['Authorization'] = @user.authentication_token
  end

  def assert_log_triggered(*args)
    stub_mixpanel
    @tracker.expects(event).with do
      yield(*args)
    end
  end

  def assert_log_not_triggered(event)
    stub_mixpanel
    @tracker.expects(event).never
  end

  def stub_mixpanel
    stub_request(:get, /.*api\.mixpanel\.com.*/)
    @tracker = Analytics::EventTracker.any_instance
  end

  def mailer_stub
    stub(deliver: true)
  end

  def stub_billing_gateway(instance)
    FactoryGirl.create(:stripe_payment_gateway, instance_id: instance.id)
  end

  def stub_active_merchant_interaction(response={success?: true})
    PaymentAuthorizer.any_instance.stubs(:gateway_authorize).returns(OpenStruct.new(response.reverse_merge({authorization: "54533"})))
    PaymentGateway.any_instance.stubs(:gateway_capture).returns(OpenStruct.new(response.reverse_merge({params: {"id" => '12345'}})))
    PaymentGateway.any_instance.stubs(:gateway_refund).returns(OpenStruct.new(response.reverse_merge({params: {"id" => '12345'}})))
    PayPal::SDK::AdaptivePayments::API.any_instance.stubs(:pay).returns(OpenStruct.new(response.reverse_merge(paymentExecStatus: "COMPLETED")))

    stub = OpenStruct.new(params: {
      "object" => 'customer',
      "id" => 'customer_1',
      "cards" => {
        "data" => [
          { "id" => "card_1" }
        ]
      }
    })
    ActiveMerchant::Billing::StripeGateway.any_instance.stubs(:store).returns(stub).at_least(0)
  end
end


ActionController::TestCase.class_eval do
  include Rails.application.routes.url_helpers
  include Devise::TestHelpers

  setup :return_default_host

  def return_default_host
    request.host =  "example.com"
  end

  def self.logged_in(factory = :admin, &block)

    context "logged in as {factory}" do

      setup do
        @user = FactoryGirl.create(factory)
        sign_in @user
      end

      merge_block(&block) if block_given?
    end

  end

  def with_versioning
    was_enabled = PaperTrail.enabled?
    was_enabled_for_controller = PaperTrail.enabled_for_controller?
    PaperTrail.enabled = true
    PaperTrail.enabled_for_controller = true
    begin
      yield
    ensure
      PaperTrail.enabled = was_enabled
      PaperTrail.enabled_for_controller = was_enabled_for_controller
    end
  end

  def spree
    Spree::Core::Engine.routes.url_helpers
  end
end

ActionMailer::Base.delivery_method = :test # Spree overrides this so we want to get back to test
DatabaseCleaner.clean_with :truncation
DatabaseCleaner.strategy = :transaction

class TestDataSeeder

  @@data_seeded = false

  def self.seed!
    if !@@data_seeded
      @@data_seeded = true
      instance = FactoryGirl.create(:instance)
      instance.set_context!
      instance.build_availability_templates
      instance.save!
      FactoryGirl.create(:transactable_type_listing, generate_rating_systems: true)
      FactoryGirl.create(:country_us)
      FactoryGirl.create(:country_pl)
      FactoryGirl.create(:seller_profile_type)
      FactoryGirl.create(:buyer_profile_type)
    end
  end
end

class DummyEvent < WorkflowStep::BaseStep
end

