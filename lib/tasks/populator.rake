namespace :populate do
  desc "Populates unit prices"
  task :prices => :environment do
    {"daily_price_cents" => 1440, "weekly_price_cents" => 10080, "monthly_price_cents" => 43200}.each do |column, period|
       ActiveRecord::Base.connection.execute("
          UPDATE listings AS l
          SET #{column} = up.price_cents
          FROM unit_prices AS up
          WHERE l.id = up.listing_id
            AND up.period = #{period}
            AND (
              l.#{column} IS NULL
              OR l.#{column} = 0
            )

        ")
    end
  end

  desc 'populates metadata for objects'
  task :metadata => :environment do
    Listing.find_each(&:populate_photos_metadata!)
    User.find_each(&:populate_companies_metadata!)
  end

  desc 'populates platform_context_details for reservations'
  task :reservation_platform_context_detail => :environment do
    Reservation.where('platform_context_detail_id is null').each do |r|
      if r.listing.present?
        if r.listing.company && r.listing.company.white_label_enabled
          puts "#{r.id} is assigned to white label company"
          r.platform_context_detail = r.listing.company
          r.save(:validate => false)
        else
          puts "#{r.id} is assigned to instance"
          r.platform_context_detail = r.listing.instance
          r.save(:validate => false)
        end
      else
        puts "Warning, #{r.id} does not belong to any listing!"
      end
    end
  end

  desc "Populates missing amenities and ensures they belong to the right amenity type"
  task :amenities => :environment do
    i = 0
    Utils::FakeDataSeeder::Data.amenities.each do |amenity_type_name, amenities_array|
      amenity_type = AmenityType.where(:name => amenity_type_name).first_or_create
      amenity_type.position = i
      amenity_type.save!
      puts "Created amenity type: #{amenity_type.name}, position #{i}"
      amenities_array.each do |amenity_name|
        amenity = Amenity.where(:name => amenity_name).first_or_create
        amenity.amenity_type = amenity_type
        amenity.save!
        puts amenity.name
      end
      i += 1
      puts "----"
    end

  end

  desc "Populates locations with address components"
  task :locations => :environment do
    limit = 500
    current_geocoding = 0

    begin
      locations = Location.all.select{|location| location.address_components.blank? }
      locations.each do |location|
        current_geocoding += 1
        raise 'Limit reached' if current_geocoding > limit
        Location::AddressComponentsPopulator.new(location, show_inspections: true).perform
      end
      puts "Done."
    rescue
      puts "Populator failed: #{$!.inspect}"
    end
  end

  desc "Populates industries"
  task :industries! => :environment do
    Industry.delete_all
    CompanyIndustry.delete_all

    Utils::FakeDataSeeder::Data.industries.each do |name|
      Industry.create(:name => name)
    end
  end

  desc "Populates top results in top cities"
  task :top_cities => :environment do
    Utils::FakeDataSeeder::Data.top_cities.each do |city_name, city|
      city.reverse.each_with_index do |listing_id, index|
        listing = Listing.find_by_id(listing_id)
        if listing
          puts "#{listing.id} > #{index+1}"
          listing.update_attribute(:rank, index+1)
        end
      end
    end
  end

  desc "Populates users with info from authentications"
  task :social_info => :environment do
    Authentication.find_each do |authentication|
      begin
        updater = Authentication::InfoUpdater.new(authentication).update
        puts "Authentication #{authentication.id}: updated with #{updater.authentication_changes.inspect}"
        puts "User #{authentication.user_id}: updated with #{updater.user_changes.inspect}"
      rescue Authentication::InvalidToken
        authentication.update_column(:token_expired, true) if authentication.token_expires?
        puts "Authentication #{authentication.id}: InvalidToken"
      rescue => e
        puts "Authentication #{authentication.id}: #{e}"
      end
    end
  end

  desc "Populates en locales"
  task :en_locales => :environment do
    Utils::EnLocalesSeeder.new.go!
  end
end
