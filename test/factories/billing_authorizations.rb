FactoryGirl.define do
  factory :billing_authorization do
    sequence(:token) { |n| "token#{n}" }
    success true
    association(:reference, :factory => :reservation_with_credit_card)

    factory :failed_billing_authorization do
      success false
    end

    factory :order_billing_authorization do
      association(:reference, :factory => :order)
    end
  end
end