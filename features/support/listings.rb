module ListingsHelpers
  def create_listing(location, name="Awesome Listing")
    visit new_manage_location_listing_url(location)
    create_listing_without_visit(location, name) do
      yield if block_given?
    end
  end

  def create_listing_without_visit(location, name="Awesome Listing")
    try_to_create_listing(location, name) do
      yield if block_given?
    end
    wait_until { @listing = Listing.find_by_name(name) }
    store_model('listing', 'user-created listing', @listing)
  end

  def try_to_create_listing(location, name="Awesome Listing")
    fill_in "Name", with: name
    fill_in "Description", with: "Nulla rutrum neque eu enim eleifend bibendum."
    fill_in "Quantity", with: "2"
    choose "listing_confirm_reservations_true"
    select "Desk"
    yield if block_given?
    click_link_or_button("Create Listing")
  end



  def set_hidden_field id, value
    page.execute_script("$('##{id}').val('#{value}')")
  end

  def listing
    @listing = model!("listing") if(!@listing)
    @listing
  end

  def create_listing_in(city)
    instance_variable_set "@listing_in_#{city.downcase.gsub(' ', '_')}",
      FactoryGirl.create("listing_in_#{city.downcase.gsub(' ', '_')}")
  end

  def build_listing_in(city, options={})

    create_listing_in(city)

    if desks = options.fetch(:desks, false)
      listing.update_column(:quantity, desks)
    end

    if num_days = options.fetch(:number_of_days, false)
      listing.availability_rules.clear

      wday = Time.now.wday
      (wday .. (wday+num_days.to_i)).each do |day|
        listing.availability_rules.create!(:day => day % 7, :open_hour => 8, :close_hour => 18)
      end
    end
  end

  def build_fully_booked_listing
    FactoryGirl.create(:fully_booked_listing)
  end

  def date_before_listing_is_fully_booked
    listing.reservations.first.periods.first.date - 1.day
  end

  def date_after_listing_is_fully_booked
    listing.reservations.first.periods.last.date +  1.day
  end
end

World(ListingsHelpers)
