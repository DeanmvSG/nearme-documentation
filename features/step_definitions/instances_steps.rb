Then(/^I should see instances list$/) do
  Instance.all.each do |instance|
    page.should have_content(instance.name)
  end
end

When(/^I fill instance form with valid details$/) do
  fill_in 'instance_name', with: 'Test instance'
  fill_in 'instance_domains_attributes_0_name', with: 'dnm.local'
  fill_in 'instance_theme_attributes_contact_email', with: 'example@example.com'
  fill_in 'user_name', with: 'Joe Smith'
  fill_in 'user_email', with: 'Joe@example.com'
end

When(/^I browse instance$/) do
  all(:css, '.table tr a').first.click
end

When(/^I edit instance$/) do
  all(:css, '.table tr .btn').first.click
end

Then(/^I should see created instance show page$/) do
  page.should have_content('Instance was successfully created.')
  page.should have_content('Test instance')
  page.should have_content('dnm.local')
end

Then(/^I should see updated instance show page$/) do
  page.should have_content('Instance was successfully updated.')
  page.should have_content('Test instance')
  page.should have_content('dnm.local')
end

Then(/^I should have blog instance created$/) do
  BlogInstance.last.name.should == 'Test instance Blog'
end
