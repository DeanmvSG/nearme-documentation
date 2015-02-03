Given /^(Location|Listing) with my details should be created$/ do |model|
  if model=='Location'
    location = Location.last
    assert_location_data(location)
  else
    listing = Transactable.last
    assert_listing_data(listing)
  end
end

Given /^#{capture_model} should not be pickable$/ do |model|
  location = Location.with_deleted.last
  within('.edit-locations') do
    page.should_not have_content(location.name, visible: true)
  end
  assert_not_nil location.deleted_at
end

Given /^TransactableType is for bulk upload$/ do
  FactoryGirl.create(:transactable_type_current_data)
end

When /^I upload csv file with locations and transactables$/ do
  FactoryGirl.create(:location_type, name: 'My Type')
  Utils::DefaultAlertsCreator::DataUploadCreator.new.notify_uploader_of_finished_import_email!
  find(:css, 'a.bulk-upload').click
  stub_image_url('http://www.example.com/image1.jpg')
  stub_image_url('http://www.example.com/image2.jpg')
  work_in_modal do
    page.should have_css('#new_data_upload')
    attach_file('data_upload_csv_file', File.join(Rails.root, *%w[test assets data_importer current_data.csv]))
    find('.btn-toolbar input[type=submit]').click
  end
  page.should_not have_css('#new_data_upload')
end

Then /^I should receive data upload report email when finished$/ do
  mails = emails_for(model!('user').email)
  assert_equal 1, mails.count
  mail = mails.first
  assert_equal "[DesksNearMe] Importing 'current_data.csv' has finished", mail.subject
end

Then /^New locations and transactables from csv should be added$/ do
  company = model!('user').companies.first
  assert_equal ['Czestochowa', 'Rydygiera'], company.locations.pluck(:name).compact.sort
  assert_equal [["my name", "Rydygiera"], ["my name2", "Rydygiera"]], company.listings.joins(:location).where('locations.name IS NOT NULL').select('name, locations.name as location_name, transactable_type_id, properties').map { |l| [l.name, l.location_name] }
end

Given /^#{capture_model} should be updated$/ do |model|
  if model=='the location'
    location = Location.last
    assert_location_data(location)
    page.should have_content(location.name, visible: true)
  else
    listing = Transactable.first
    assert_listing_data(listing, true)
  end
end

When /^I fill (location|listing) form with valid details$/ do |model|
  if model == 'location'
    fill_location_form
  else
    fill_listing_form
  end
end

When /^I (disable|enable) (.*) pricing$/ do |action, period|
  page.find("#enable_#{period}").set(action == 'disable' ? false : true)
  if action=='enable'
    if page.has_selector?("#listing_#{period}_price")
      page.find("#listing_#{period}_price").set(15.50)
    else
      page.find("#transactable_#{period}_price").set(15.50)
    end
  end

end

When /^I provide new (location|listing) data$/ do |model|
  if model == 'location'
    fill_location_form
  else
    fill_listing_form
  end
end

When /^I submit the location form$/ do
  page.find('#location-form input[type=submit]').click
end

When /^I submit the transactable form$/ do
  page.find('#listing-form input[type=submit]').click
end

When /^I submit the form$/ do
  page.find('#submit-input').click
end

When /^I click edit location icon$/ do
  page.find('.location .edit').click
end

When /^I click edit listing icon$/ do
  page.find('.listing .edit').click
end

When /^I click delete location link$/ do
  page.evaluate_script('window.confirm = function() { return true; }')
  click_link "Delete this location"
end

When /^I click delete bookable noun link$/ do
  page.evaluate_script('window.confirm = function() { return true; }')
  click_link "Delete this #{model!('theme').bookable_noun}"
end

Then /^Listing (.*) pricing should be (disabled|enabled)$/ do |period, state|
  enable_period_checkbox = page.find("#enable_#{period}")
  if state=='enabled'
    assert enable_period_checkbox.checked?
    if page.has_selector?("#listing_#{period}_price")
      assert_equal "15.50", page.find("#listing_#{period}_price").value
    else
      assert_equal "15.50", page.find("#transactable_#{period}_price").value
    end
  else
    assert !enable_period_checkbox.checked?
  end
end

Then /^pricing should be free$/ do
  if page.has_selector?("#listing_price_type_free")
    page.find("#listing_price_type_free").checked?
  else
    page.find("#transactable_price_type_free").checked?
  end
end

When /^I select custom availability:$/ do |table|
  choose 'availability_rules_custom'

  days = availability_data_from_table(table)
  days.each do |day, rule|
    within ".availability-rules .day-#{day}" do
      if rule.present?
        page.find('.open-checkbox').set(true)
        page.find("select[name*=open_time] option[value='#{rule[:open]}']").select_option
        page.find("select[name*=close_time] option[value='#{rule[:close]}']").select_option
      else
        page.find('.open-checkbox').set(false)
      end
    end
  end
end

Then /^#{capture_model} should have availability:$/ do |model, table|
  object = model!(model)
  days = availability_data_from_table(table)

  object.availability.each_day do |day, rule|
    if days[day].present?
      assert rule, "#{day} should have a rule"
      oh, om = days[day][:open].split(':').map(&:to_i)
      ch, cm = days[day][:close].split(':').map(&:to_i)
      assert_equal oh, rule.open_hour, "#{day} should have open hour = #{oh}"
      assert_equal om, rule.open_minute, "#{day} should have open minute = #{om}"
      assert_equal ch, rule.close_hour, "#{day} should have close hour = #{ch}"
      assert_equal cm, rule.close_minute, "#{day} should have close minute = #{cm}"
    else
      assert_nil rule, "#{day} should not be open"
    end
  end

end

And /^I populate listing metadata for all users$/ do
  User.all.each { |u| u.populate_listings_metadata! }
end

