Given /^a location exists with organizations$/ do
  @location = FactoryGirl.create(:location, organizations: [FactoryGirl.create(:aarp)])
end
When /^I create a location for that company$/ do
  create_location
end

When /^I create a location with that organization$/ do
  create_location do
    check model("organization").name
  end
end

When /^I create a location with an alternative currency/ do
  create_location do
    select "EUR - Euro", from: "Currency"
  end
end

When /^I create a private location with that organization$/ do
  create_location do
    check model("organization").name
    check "location_require_organization_membership"
  end
end

When /^I create a location with that amenity$/ do
  create_location do
    check model!('amenity').name
  end
end

Then /^that location has that (\w+)$/ do |resource|
  @location.send(resource.pluralize).should include model!(resource)
end

Then /^that location has that alternative currency$/ do
  @location.currency.should == "EUR"
end

Then /^that location is private to only members of it's organizations$/ do
  @location.require_organization_membership?.should be_true
end

When /^I change that locations name to Joe's Codin' Garage$/ do
  visit edit_manage_location_path model!('location')
  fill_in "Space name", with: "Joe's Codin' Garage"
  click_link_or_button "Update Location"
end

When /^I delete that location$/ do
  visit manage_company_locations_path model!('location').company
  click_link_or_button "Delete"
end

Then /^that location no longer exists$/ do
  expect { model!('location') }.to raise_error ActiveRecord::RecordNotFound
end
