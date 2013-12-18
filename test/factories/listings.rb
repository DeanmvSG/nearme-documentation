FactoryGirl.define do
  factory :listing do
    sequence(:name) do |n|
      "Listing #{n}"
    end

    description "Aliquid eos ab quia officiis sequi."
    location
    association :listing_type
    confirm_reservations true
    daily_price_cents 5000
    hourly_reservations false

    photo_not_required true
    ignore do
      photos_count_to_be_created 1
    end

    after(:build) do |listing, evaluator|
      listing.photos = create_list(:photo, evaluator.photos_count_to_be_created,
                                   listing: nil,
                                   creator: listing.location.creator)
      listing.photos_count = evaluator.photos_count_to_be_created
    end

    factory :always_open_listing do
      after(:create) do |listing|
        listing.availability.each_day do |dow, rule|
          listing.availability_rules.create!(:day => dow, :open_hour => 9, :close_hour => 18)
        end
      end
    end

    factory :free_listing do
      after(:create) do |listing|
        listing.daily_price_cents = 0
        listing.free = true
      end
    end

    factory :hundred_dollar_listing do
      after(:create) do |listing|
        listing.daily_price_cents = 100_00
      end
    end

    factory :call_listing do
      after(:create) do |listing|
        listing.daily_price_cents = nil
      end
    end

    factory :listing_at_5_5 do
      association(:location, factory: :location, latitude: "5.0", longitude: "5.0")
    end

    factory :listing_in_auckland do
      sequence(:name) do |n|
        "Listing in Auckland #{n}"
      end

      association(:location, factory: :location_in_auckland)
    end

    factory :listing_in_adelaide do
      sequence(:name) do |n|
        "Listing in Adeilaide #{n}"
      end

      association(:location, factory: :location_in_adelaide)
    end

    factory :listing_in_cleveland do
      sequence(:name) do |n|
        "Listing in Cleveland #{n}"
      end

      association(:location, factory: :location_in_cleveland)

      factory :fully_booked_listing_in_cleveland do
        after(:create) do |listing|
          user = FactoryGirl.create(:user)
          dates = (4.days.from_now.to_date..10.days.from_now.to_date).reject { |d| listing.availability_for(d) == 0 }.to_a
          listing.reserve!(PlatformContext.new, user, dates, listing.quantity)
        end
      end
    end

    factory :listing_in_san_francisco do
      sequence(:name) do |n|
        "Listing in San Francisco #{n}"
      end

      association(:location, factory: :location_in_san_francisco)
    end


    factory :listing_in_san_francisco_address_components do
      sequence(:name) do |n|
        "Listing in San Francisco #{n}"
      end

      association(:location, factory: :location_san_francisco_address_components)
    end

    factory :listing_in_wellington do
      sequence(:name) do |n|
        "Listing in Wellington #{n}"
      end

      association(:location, factory: :location_in_wellington)
    end

    factory :demo_listing do
      daily_price_cents { 5000 + (100 * rand(50)).to_i }

      after(:create) do |listing, evaluator|
        listing.photos = FactoryGirl.create_list(:demo_photo, 2, creator: listing.location.creator )
        listing.save!
      end
    end

  end
end
