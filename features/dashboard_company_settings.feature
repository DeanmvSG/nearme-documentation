Feature: A user can edit their settings
  In order to escape an ex-girlfriend from emailing me
  As a user
  I want to be able to change my email address

  Background:
    Given a user exists
    And I am logged in as the user

  Scenario: A user with listing will see settings
    Given a transactable_type_listing exists with name: "Desk"
      And a company exists with creator: the user
      And a location exists with company: the company
      And a transactable exists with location: the location
      And I am on the home page
    Then I should see "Manage Desks"

  Scenario: A user can update existing company
    Given a company exists with creator: the user
    And a transactable_type exists with name: "Desk"
    And I go to the settings page
    When I update company settings
    Then The company should be updated

  Scenario: A user can update payouts settings
    Given a company exists with creator: the user
    Given paypal gateway is properly configured
    And I go to the payouts page
    When I update payouts settings
    Then The company payouts settings should be updated


  Scenario: A user can update payouts settings when payout gateway is missing
    Given a company exists with creator: the user
    Given no payout gateway defined
    And I go to the payouts page
    When I update payouts settings
    Then The company payouts settings should be updated

  Scenario: A user without listing will not see settings
    Given a company exists with creator: the user
      And a location exists with company: the company
      And I am on the home page
    Then I should not see "Manage Desks"

  Scenario: A user with one inactive listing will not see settings
    Given a draft_company exists with creator: the user
      And a location exists with company: the company
      And a transactable exists with location: the location, draft: "#{Time.zone.now}"
      And I am on the home page
    Then I should not see "Manage Desks"
