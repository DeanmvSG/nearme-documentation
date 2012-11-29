Feature: As a user of the site
  In order for them to manage their reservations / listings
  As a user
  I want to view the dashboard

  Background:
    Given a user exists
      And I am logged in as the user
      And a company exists with creator: the user
      And a location exists with company: the company, creator: the user, name: "Rad Annex House"
      And a listing exists with location: the location, creator: the user, name: "Rad Annex", confirm_reservations: true

  Scenario: A user can see their listings
     When I am on the dashboard
     And  I follow "Manage Spaces"
     And I follow "Spaces"
     And I follow "Edit"
     And I follow "Desks & Rooms"
     Then I should see "Rad Annex"
      And I should see "Edit"


