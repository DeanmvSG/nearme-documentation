namespace :populate do

  desc "Populates missing amenities and ensures they belong to the right amenity type"
  task :amenities => :environment do
    amenities_hash = {
      'Food' => [
        'Coffee/Tea', 'Espresso', 'Fridge',
        'Kitchen', 'Microwave', 'Refreshments',
        'Vending Machine'
      ],

      'Access' => [
        '24/7 Access', 'Eateries Nearby', 'Elevator Access',
        'Handicap Access', 'Parking', 'Street Parking',
        'Transport Nearby'
      ],

      'Rooms' => [
        'Conference Room', 'Lounge Area', 'Lunch Room',
        'Meeting Rooms', 'Multi-purpose Room', 'Shower Room',
        'Yard Area'
      ],

      'Facilities' => [
        'Administrative Assistant', 'Copier', 'Fax',
        'Internet Access', 'IT Support', 'Mail Service',
        'Monitors', 'Printer', 'Projector',
        'Receptionist', 'Scanner', 'Telephone',
        'Videoconferencing Facilities', 'Whiteboard'
      ],

      'Entertainment' => [
        'Games',
        'Gym',
        'Happy Hour',
        'Ping Pong Table',
        'Recreational Facilities',
        'Television'
      ],

      'Kids & Pets' => [
        'Child Friendly',
        'Childrens Playroom',
        'Pet Friendly'
      ]
    }

    i = 0
    amenities_hash.each do |amenity_type_name, amenities_array|
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

end
