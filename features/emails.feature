Feature: Emails should be sent out informing parties about bookings
  In order to know or change the status of a booking
  As a user or workplace owner
  I want to receive emails updating me about the status of my bookings

  # Emails
  #
  # 1. When user creates a booking, one of (depending on confirmation setting) [DONE]:
  #   a) email to owner asking to confirm/decline [DONE]
  #   b) email to owner telling them that a booking has been made [DONE]
  # 2. When user cancels a booking, send email to owner
  # 3. When owner cancels a booking, send email to user
  # 4. When owner declines a booking, send email to user
  # 5. When owner confirms a booking, send email to user
  # 6. When user creates a booking, one of (depending on confirmation) [DONE]
  #   a) email to user telling them to wait for confirmation [DONE]
  #   b) email to user telling them their booking is confirmed [DONE]


  Background:
    Given the date is "13th October 2010"
    And a user: "Keith Contractor" exists with name: "Keith Contractor"
    And a user: "Bo Jeanes" exists with name: "Bo Jeanes"

  Scenario: booking confirmations required
    Given a workplace: "Mocra" exists with name: "Mocra", creator: user "Bo Jeanes", confirm_bookings: true
    And I am logged in as user "Keith Contractor"
    When I go to the workplace's page
    And I follow the booking link for "15th October 2010"
    And I press "Book"
    Then 2 emails should be delivered
    And the 1st email should be delivered to user "Bo Jeanes"
    And the 1st email should have subject: "[DesksNear.Me] A new booking requires your confirmation"
    And the 1st email should contain "Bo Jeanes,"
    And the 1st email should contain "Keith Contractor has made a booking for Mocra on October 15, 2010"
    And the 2nd email should be delivered to user "Keith Contractor"
    And the 2nd email should have subject: "[DesksNear.Me] Your booking is pending confirmation"
    And the 2nd email should contain "Dear Keith Contractor,"
    And the 2nd email should contain "You have made a booking for Mocra on October 15, 2010."

  Scenario: booking confirmations not required
    Given a workplace: "Mocra" exists with creator: user "Bo Jeanes", confirm_bookings: false
    And I am logged in as user "Keith Contractor"
    When I go to the workplace's page
    And I follow the booking link for "15th October 2010"
    And I press "Book"
    Then 2 emails should be delivered
    And the 1st email should be delivered to user "Keith Contractor"
    And the 1st email should have subject: "[DesksNear.Me] Your booking has been confirmed"
    And the 2nd email should be delivered to user "Bo Jeanes"
    And the 2nd email should have subject: "[DesksNear.Me] You have a new booking"

  Scenario: booking gets confirmed
    Given a workplace: "Mocra" exists with name: "Mocra", creator: user "Bo Jeanes", confirm_bookings: true
    And a booking exists with workplace: workplace "Mocra", user: user "Keith Contractor", date: "2010-10-15"
    And all emails have been delivered
    And I am logged in as user "Bo Jeanes"
    When I follow "Dashboard"
    And I press "Confirm"
    Then show me the page
    Then 1 email should be delivered
    And the email should be delivered to user "Keith Contractor"
    And the email should have subject: "[DesksNear.Me] Your booking has been confirmed"

  @wip
  Scenario: confirmed then cancelled by user
    Given a workplace: "Mocra" exists with name: "Mocra", creator: user "Bo Jeanes", confirm_bookings: true
    And a booking exists with workplace: workplace "Mocra", user: user "Keith Contractor", date: "2010-10-15", state: "confirmed"
    And all emails have been delivered
    And I am logged in as user "Keith Contractor"
    # When

  @wip
  Scenario: confirmed then cancelled by owner
    Given a workplace: "Mocra" exists with name: "Mocra", creator: user "Bo Jeanes", confirm_bookings: true
    And a booking exists with workplace: workplace "Mocra", user: user "Keith Contractor", date: "2010-10-15", state: "confirmed"
    And all emails have been delivered
    And I am logged in as user "Keith Contractor"

  @wip
  Scenario: unconfirmed booking gets cancelled by user
    Given a workplace: "Mocra" exists with name: "Mocra", creator: user "Bo Jeanes", confirm_bookings: true
    And a booking exists with workplace: workplace "Mocra", user: user "Keith Contractor", date: "2010-10-15", state: "unconfirmed"
    And all emails have been delivered
    And I am logged in as user "Keith Contractor"

  @wip
  Scenario: unconfirmed booking gets rejected
    Given a workplace: "Mocra" exists with name: "Mocra", creator: user "Bo Jeanes", confirm_bookings: true
    And a booking exists with workplace: workplace "Mocra", user: user "Keith Contractor", date: "2010-10-15", state: "unconfirmed"
    And all emails have been delivered
    And I am logged in as user "Keith Contractor"
