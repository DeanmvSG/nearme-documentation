FactoryGirl.define do
  factory :user do
    sequence(:name) {|n| "User-#{n}"}
    email { "#{name.to_s.underscore.downcase.tr(' ', '_')}@example.com" }
    password 'password'
    password_confirmation 'password'
    country_name "United States"
    phone "18889983375"
    mobile_number "18889983375"
    current_location "Prague"
    company_name "DesksNearMe"
    last_geolocated_location_longitude 14.437800
    last_geolocated_location_latitude 50.075538
    sms_notifications_enabled true
    sms_preferences { Hash[%w(user_message reservation_state_changed new_reservation).map{|sp| [sp, '1']}] }
    instance_unread_messages_threads_count Hash.new

    factory :user_without_country_name do
      country_name nil
    end

    factory :admin do
      admin true
    end

    factory :creator do
      sequence(:name) {|n| "Creator-#{n}"}
    end

    factory :authenticated_user do
      sequence(:name) {|n| "Authenticated-User-#{n}"}
      authentication_token "EZASABC123UANDME"
    end

    factory :demo_user do
      avatar { fixture_file_upload(Dir.glob(Rails.root.join('db', 'seeds', 'demo', 'desksnearme', 'assets', 'avatars', '*')).sample, 'image/jpeg') }
      avatar_versions_generated_at Time.zone.now
    end

    factory :user_without_password do

      after(:create) do |u|
        u.encrypted_password = ''
        u.save!(:validate => false)
      end

    end
  end


end
