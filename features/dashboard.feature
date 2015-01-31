@javascript
Feature: As a user of the site
  In order to promote my company
  As a user
  I want to manage my locations

  Background:
    Given a user exists
      And I am logged in as the user
      And a company exists with creator: the user
      And a location_type exists with name: "Business"
      And a location_type exists with name: "Co-working"
      And a transactable_type_listing exists with name: "Listing"
      And a amenity_type exists with name: "AmenityType1"
      And a amenity exists with amenity_type: the amenity_type, name: "Amenity1"
      And a amenity exists with amenity_type: the amenity_type, name: "Amenity2"
      And a amenity exists with amenity_type: the amenity_type, name: "Amenity3"
      And the transactable_type_listing exists

  Scenario: A user can add new location
    Given I am adding new transactable
     When I add a new location
      And I fill location form with valid details
      And I submit the location form
      And I should see "Great, your new location has been added!"
     Then Location with my details should be created

  Scenario: A user can edit existing location
    Given the location exists with company: the company
     And I am adding new transactable

     When I edit first location
      And I provide new location data
      And I submit the location form
     Then I should see "Great, your location has been updated!"
      And the location should be updated
      And I remove first location
      And I should see "You've deleted"
     Then the location should not be pickable

  Scenario: A user can add new listing
    Given the location exists with company: the company
     And I am browsing transactables
     When I add a new transactable
      And I fill listing form with valid details
      And I submit the transactable form
      And I should see "Great, your new Desk has been added!"
     Then Listing with my details should be created

  Scenario: A user can add locations and listings via bulk upload
    Given TransactableType is for bulk upload
      And I am browsing bulk upload transactables
     When I upload csv file with locations and transactables
     Then I should see "Import has been scheduled. You'll receive an email when it's done."
      And I should receive data upload report email when finished
      And New locations and transactables from csv should be added

  Scenario: A user can edit existing listing
    Given the location exists with company: the company
      And the transactable exists with location: the location
      And I am browsing transactables
     When I edit first transactable
      And I provide new listing data
      And I submit the transactable form
      And I should see "Great, your listing's details have been updated."
     Then the transactable should be updated
     When I remove first transactable
      And I should see "That listing has been deleted."
     Then the transactable should not exist

  Scenario: A user can disable existing price in listing
    Given a location exists with company: the company
      And a transactable exists with location: the location, daily_price_cents: 1000, photos_count: 1
      And I am browsing transactables
     When I edit first transactable
      And I disable daily pricing
      And I choose "transactable_price_type_free"
      And I submit the transactable form
      And I edit first transactable
     Then pricing should be free

  Scenario: A user can enable new pricing in listing
    Given a location exists with company: the company
      And a transactable exists with location: the location, daily_price_cents: 1000, photos_count: 1
      And I am browsing transactables
     When I edit first transactable
      And I enable weekly pricing
      And I submit the transactable form
      And I edit first transactable
     Then Listing weekly pricing should be enabled

  Scenario: A user can set availability rules on a transactable
    Given a location exists with company: the company
    And   a transactable exists with location: the location, photos_count: 1
    And I am browsing transactables
    When I edit first transactable
    And  I select custom availability:
        | Day | Availabile | Open Time | Close Time |
        | 1   | Yes        | 9:00      | 17:00      |
        | 2   | Yes        | 9:00      | 17:00      |
    And I submit the transactable form
    And I should see "Great, your listing's details have been updated."
    Then the transactable should have availability:
        | Day | Availabile | Open Time | Close Time |
        | 1   | Yes        | 9:00      | 17:00      |
        | 2   | Yes        | 9:00      | 17:00      |

  Scenario: A user can't manage blog if blogging is disabled on instance
    Given I visit blog section of dashboard
    Then I should see "Marketplace owner has disabled blog functionality"

  Scenario: A user can manage blog if blogging is enabled on instance
    Given user blogging is enabled for my instance
    Then I should be able to enable my blog

