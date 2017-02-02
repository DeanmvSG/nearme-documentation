require Rails.root.join('lib', 'tasks', 'uot', 'uot_setup.rb')

Given /^UoT instance is loaded$/ do
  @instance = Instance.first
  PaymentGateway.where(instance_id: @instance.id).destroy_all
  @instance.update_attributes(
    split_registration: true,
    enable_reply_button_on_host_reservations: true,
    hidden_ui_controls: {
      'main_menu/cta': 1,
      'dashboard/offers': 1,
      'dashboard/user_bids': 1,
      'dashboard/host_reservations': 1,
      'main_menu/my_bookings': 1
    },
    skip_company: true,
    click_to_call: true,
    wish_lists_enabled: true,
    default_currency: 'USD',
    default_country: 'United States',
    force_accepting_tos: true,
    user_blogs_enabled: true,
    force_fill_in_wizard_form: true
  )

  setup = UotSetup.new(@instance)
  setup.create_transactable_types!
  setup.create_custom_attributes!
  setup.create_custom_model!
  setup.create_categories!
  setup.create_or_update_form_components!
  setup.set_theme_options
  setup.create_content_holders
  setup.create_views
  # setup.create_translations
  # setup.create_workflow_alerts
  setup.expire_cache
end

When /^I fill all required buyer profile information$/ do
  Category.update_all('mandatory = false')
  step 'I upload avatar'
  fill_in "user[current_address_attributes][address]", with: "usa"
  fill_in "user[buyer_profile_attributes][properties_attributes][linkedin_url]", with: "http://linkedin.com/tomek"
  fill_in "user[buyer_profile_attributes][properties_attributes][hourly_rate_decimal]", with: "1"
  fill_in "user[buyer_profile_attributes][properties_attributes][bio]", with: "Bio"
end

When /^I fill all required seller profile information$/ do
  Category.update_all('mandatory = false')
  step 'I upload avatar'
  fill_in "user[companies_attributes][0][name]", with: "Appko"
  fill_in "user[current_address_attributes][address]", with: "usa"
  fill_in "user[seller_profile_attributes][properties_attributes][linkedin_url]", with: "http://linkedin.com/tomek"
end

Then /^I can add new project$/ do
  fill_in 'transactable[name]', with: 'Cucumber project'
  fill_in 'transactable[properties_attributes][about_company]', with: 'About me'
  fill_in 'transactable[properties_attributes][estimation]', with: '1 week'
  fill_in 'transactable[properties_attributes][deadline]', with: '11-01-2022'
  click_button 'Save'
end

And /^only credit_card payment_method is set$/ do
  model('stripe_connect_payment_gateway').payment_methods.ach.destroy_all
end

And /^I invite enquirer to my project$/ do
  page.should have_css('a[data-project-invite-trigger]')
  find('a[data-project-invite-trigger]').click
  page.should have_css(".project-invite-content form button.button-a")
  page.find('.project-invite-content form button.button-a').click
  page.should_not have_css(".project-invite-content form button.button-a")
  assert Transactable.last.transactable_collaborators.any?
end

And /^I wait for modal with credit card fields to render$/ do
  page.should have_css(".nm-new-credit-card-form-name-container")
end

Then /^I fill credit card payment subscription form$/ do
  # I submit empty form to check validation
  find('.dialog__actions button').trigger('click')
  page.should have_content('required')

  fill_in 'payment_subscription_credit_card_attributes_first_name', with: 'FirstName'
  fill_in 'payment_subscription_credit_card_attributes_last_name', with: 'LastName'
  # note we provide invalid credit card number on purpose - payment.js should validate the input and remove unnecessary 555
  page.execute_script("$('#payment_subscription_credit_card_attributes_number').val('42 42424 24242 4242 555').trigger('change')")
  find('.payment_subscription_credit_card_month').find("option[value='12']").select_option
  find('.payment_subscription_credit_card_year').find("option[value='2024']").select_option
  fill_in 'payment_subscription_credit_card_attributes_verification_value', :with => '411'

  find('.dialog__actions button').trigger('click')
end

Then /^I fill credit card payment form$/ do
  # I submit empty form to check validation
  find('.dialog__actions button').trigger('click')
  page.should have_content('required')

  fill_in 'payment_credit_card_attributes_first_name', with: 'FirstName'
  fill_in 'payment_credit_card_attributes_last_name', with: 'LastName'
  # note we provide invalid credit card number on purpose - payment.js should validate the input and remove unnecessary 555
  page.execute_script("$('#payment_credit_card_attributes_number').val('42 42424 24242 4242 555').trigger('change')")
  find('.payment_credit_card_month').find("option[value='12']").select_option
  find('.payment_credit_card_year').find("option[value='2024']").select_option
  fill_in 'payment_credit_card_attributes_verification_value', :with => '411'

  find('.dialog__actions button').trigger('click')
end

Then /^offer is confirmed$/ do
  find('.table-responsive').should have_text('Accepted')
  assert Offer.last.confirmed?
end

And /^my credit card is saved$/ do
  find('#dashboard-nav-credit_cards a', visible: false).trigger('click')
  page.should have_text('Manage Credit Cards')
  page.should have_text('**** **** ****')
end

And /^payment for (\d+)\$ was created$/ do |amount|
  assert Offer.last.paid?
  assert_equal amount.to_money, Payment.last.total_amount
end
