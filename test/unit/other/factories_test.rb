require 'test_helper'

class FactoriesTest < ActiveSupport::TestCase

  SPREE_EXCLUDED_FACTORIES = ['admin_user', 'user_with_addreses', 'reservation_request', 'reservation_request_with_not_valid_cc']

  FactoryGirl.factories.each do |factory|
    next if factory.class_name.to_s.gsub(/::.*/, '') == 'Spree' ||
      SPREE_EXCLUDED_FACTORIES.include?(factory.name.to_s)

    context "Factory: #{factory.name}" do
      should "return valid resource" do
        stub_us_geolocation
        resource = FactoryGirl.build(factory.name)
        assert resource.valid?, "Resource (#{factory.name}) invalid because of: #{resource.errors.full_messages.join(", ")}" if resource.respond_to?(:valid)
      end
    end
  end

end
