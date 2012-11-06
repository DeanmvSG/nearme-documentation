Feature: A user can add a space
  In order to let people easily list a space
  As a user
  I want to be able to step through an 'Add Space' wizard

  Scenario: An unregistered user starts by signing up
    Given I go to the home page
     And  I follow "List Your Space!"
     Then I should be at the "Sign Up" step
     When I fill in "Your name" with "Brett Jones"
     And I fill in "Your email address" with "brettjones@email.com"
     And I fill in "Your password" with "password"
     And I fill in "user_password_confirmation" with "password"
     When I press "Sign up and get started"
     Then a user should exist with email: "brettjones@email.com"
     And I should be at the "Company" step
     When I fill in "Your company name" with "My Company"
     And I fill in "Company website URL" with "http://google.com"
     And I fill in "Company email" with "email@mycompany.com"
     And I fill in "Company description" with "My Description"
     When I press "Create My Company"
     Then a company should exist with name: "My Company"
     And I should be at the "Your Space" step
     When I fill in "Space name" with "My Office"
     And I fill in "Space location" with "usa"
     And I fill in "Space description" with "Awesome space"
     And I fill in "Booking email" with "bookings@mycompany.com"
     And I fill in "Booking phone #" with "123456"
     And I fill in "Special terms or notes" with "My special terms"
     When I press "Create my space"
     Then a location should exist with name: "My Office"
     And I should be at the "Desks & Rooms" step
     When I fill in "Name" with "Conference Room"
     And I fill in "Quantity available" with "2"
     And I fill in "Description" with "Awesome conference room"
     And I fill in "Price per day" with "200"
     And I choose "Yes"
     And I press "I'm Done, Save and Continue"
     Then I should see "Great, your space has been set up!"

