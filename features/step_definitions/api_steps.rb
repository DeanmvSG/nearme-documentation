Given /^I am an authenticated api user$/ do
  @user = FactoryGirl.create(:user)
  post "/v1/authentication", { email: @user.email, password: 'password' }.to_json
  fail "User was not authenticated" unless last_response.ok?
  @user.reload
end

Given /^an amenity named (.*)$/ do |name|
  FactoryGirl.create(:amenity, name: name)
end

Given /^an organization named (.*)$/ do |name|
  FactoryGirl.create(:organization, name: name)
end

Given /^an organization with logo named (.*)$/ do |name|
  FactoryGirl.create(:organization_with_logo, name: name)
end

Given /^a listed location with an organization with the id of 1$/ do
  FactoryGirl.create(:listing_with_organization)
end

Given /^a listed location( without (amenities|organizations))?$/ do |_,_|
  @listing = FactoryGirl.create(:listing)
end

Given /^a listed location with an amenity with the id of 1$/ do
  FactoryGirl.create(:listing_with_amenity)
end

When /^I send a(n authenticated)? POST request to "(.*?)":$/ do |authenticated, url, body|
  if url.match(/:id/) && plural_resource = url.match(/^(\w+)\/.*/)
    this_resource = instance_variable_get("@#{plural_resource.captures.first.singularize}")
    parsed_url = url.gsub(/:(\w+)/) {|message| this_resource.send $1}
    header 'Authorization', @user.authentication_token if authenticated
  else
    parsed_url = url
  end

  @response = post "/v1/#{parsed_url}", body
end

When /^I send a GET request for "(.*?)"$/ do |url|
  @response = get "/v1/#{url}"
end

Then /^I receive only listings which have that amenity$/ do
  results = parse_json(last_json)
  results.size.should == 1
  results.all? do |r|
    r["amenities"].any? { |a| a["id"] == 1 }
  end
end

Then /^I receive only listings which have that organization$/ do
  results = parse_json(last_json)
  results.size.should == 1
  results.all? do |r|
    r["organizations"].any? { |a| a["id"] == 1 }
  end
end

Then /^I receive a response with (\d+) status code$/ do |status_code|
  last_response.status.should == status_code.to_i
end
