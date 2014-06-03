FactoryGirl.define do

  factory :refund do
    association(:reference, :factory => :reservation_charge)
    created_at { Time.zone.now }
    success true
    amount 1000
    currency 'USD'
  end
end
