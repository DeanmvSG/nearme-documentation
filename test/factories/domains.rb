FactoryGirl.define do
  factory :domain do
    sequence(:name) {|n| "desksnear#{n}.me" }
    target_type "Instance"
    target_id { (Instance.first.presence || FactoryGirl.create(:instance)).id }
    use_as_default { target.respond_to?(:domains) && target.domains.default.any? ? false : true }

    factory :secured_domain do
      secured true
      private_key "ahoj"
      certificate_body "ahoj"
    end

    factory :unsecured_domain do
      secured false
    end

    factory :desksnearme_domain do
      name 'desksnearme.com'
    end

    factory :test_domain do
      name 'example.com'
    end
  end
end
