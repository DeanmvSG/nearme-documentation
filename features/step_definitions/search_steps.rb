When /^I search for "([^"]*)"$/ do |text|
  search_for(text)
end

When /^I search for located "([^"]*)"$/ do |text|
  SearchController.any_instance.stubs(:params).returns(ActionController::Parameters.new({:lat => 1, :lng => 1, :loc => text}))
  search_for(text)
end

Given /^Auckland listing has fixed_price: (.*)$/ do |fixed_price|
  listing = Transactable.last
  listing.min_fixed_price_cents = 0
  listing.max_fixed_price_cents = fixed_price.to_i * 100 + 1
  listing.fixed_price_cents = fixed_price.to_i * 100
  listing.action_free_booking = true if !listing.has_price?
  listing.save(validate: false)
end

Given /^this listing has location type (.*)$/ do |lntype|
  location = Transactable.last.location
  location_type = LocationType.where(name: lntype).first_or_create!(instance_id: PlatformContext.current.instance.id)
  location.location_type = location_type
  location.save(validate: false)
end

Given /^Elasticsearch is turned (.*)$/ do |switch|
  if switch.strip.downcase == 'on'
    Instance.update_all(search_engine: Instance::SEARCH_ENGINES.last)
  else
    Instance.update_all(search_engine: Instance::SEARCH_ENGINES.first)
  end
end

Then /^Elasticsearch (.*) index should be (.*)$/ do |index_name, action_name|
  if index_name == 'transactables'
    if action_name == 'created'
      Transactable.searchable.import force: true
    else
      Transactable.__elasticsearch__.client.indices.delete index: Transactable.index_name
    end
  elsif index_name == 'products'
    if action_name == 'created'
      Spree::Product.searchable.import force: true
    else
      Spree::Product.__elasticsearch__.client.indices.delete index: Spree::Product.index_name
    end
  end
end

Then /^I see all results for location types (.*) and (.*)$/ do |lntype1, lntype2|
  Transactable.all.select{|t| [lntype1, lntype2].include?(t.location.location_type.name)}.each do |t|
    page.should have_selector('.listing[data-id="' + t.id.to_s + '"]')
  end
end

Then /^I click on Location Types$/ do
  click_link 'Location Types'
end

When /^I (check|uncheck) location type (.*)$/ do |action_type, lntype|
  include_hidden_fields do
    find("input[value='#{lntype.downcase}']").click
  end
  while (page.evaluate_script('$.active') == 0) do
    sleep(1)
  end
end

Then /^I do( not)? see result for the (.*) listing$/ do |confirmation, lntype|
  listing = Transactable.all.select{|t| lntype == t.location.location_type.name}.first
  listing_selector = '.listing[data-id="' + listing.id.to_s + '"]'
  if !confirmation
    page.should have_selector(listing_selector)
  else
    page.should_not have_selector(listing_selector)
  end
end

When /^I search for "([^"]*)" with prices (\d+) (\d+)$/ do |query, min, max|
  visit search_path(:q => query, "price[min]" => min, "price[max]" => max, :lgpricing => "fixed")
end

When /^I search for product "([^"]*)"$/ do |text|
  search_for_product(text)
end

When /^I performed search for "([^"]*)"$/ do |query|
  visit search_path(:q => query)
end

When /^I search for "([^"]*)" with location type (.*) forcing list view$/ do |query, lntype|
  visit search_path(q: query, lntype: lntype.downcase, v: 'list')
end

When /^I make another search for "([^"]*)"$/ do |query|
  visit root_path
  search_for(query)
end

When /^I leave the page and hit back$/ do
  visit root_path
  page.evaluate_script('window.history.back()')
end

Then /^I should see a notification for my subscription$/ do
  page.find('.alert').should have_content("You will be notified when this location will be added.")
end

Then /^I (do not )?see a search results for the ([^\$].*)$/ do |negative, product|
  product = model!(product)
  if negative
    page.should have_no_selector('.result-item[data-product-id="' + product.id.to_s + '"]')
  else
    page.should have_selector('.result-item[data-product-id="' + product.id.to_s + '"]')
  end
end
