@javascript
Feature: A user can add a space
  In order to let people easily list a space
  As a user
  I want to be able to step through an 'Add Space' wizard
  Background:
    Given a location_type exists with name: "Business"
    Given a location_type exists with name: "Public Space"
    Given a transactable_type_listing exists with name: "Listing"
    And a form component exists with form_componentable: the transactable_type_listing
    And a industry exists with name: "Industry"
    And a country_nz exists

    Given I go to the home page
    And I follow "List Your" bookable noun
    And I sign up as a user in the modal
    Then I should see "List Your First" bookable noun

  Scenario: An unregistered user starts a draft, comes back to it, and saves it
    And I partially fill in space details
    And I press "Submit"
    Then I should see "Please complete all fields! Alternatively, you can Save for later."
    And I press "Save as draft"
    Then I should see "Your draft has been saved!"
    And I fill in valid space details
    And I press "Submit"
    Then I should see "Your Desk was listed!"

  Scenario: An unregistered user starts by signing up
    When I fill in valid space details
    And I press "Submit"
    Then I should see "Your Desk was listed!"

  Scenario: An unregistered user starts by signing up
    When custom validator exists for field location_type_id
    And I press "Submit"
    Then I should see shortened error messages

