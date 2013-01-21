FactoryGirl.define do
  factory :reservation do
    association :user
    association :listing
    date { Date.today }

    factory :reservation_with_credit_card do
      payment_method Reservation::PAYMENT_METHODS[:credit_card]
    end
  end
end
