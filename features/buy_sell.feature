@javascript
Feature: Buy Sell Marketplace
  In order to buy something on marketplace
  As a user
  I want to accomplish full checkout flow

  Background:
    Given a user exists
    And Current marketplace is buy_sell
    And I am logged in as the user

  Scenario: A user can buy a product
    Given A buy sell product exist in current marketplace
    When I search for buy sell "Product"
    Then I should see relevant buy sell products
    When I add buy sell product to cart
    Then The product should be included in my cart
    When I begin Checkout process
    When I fill in shippment details
    And  I choose shipping method
    Then I should see order summary page
    When I fill billing data
    Then I should see order summary page
    And  I should see order placed confirmation

  Scenario: A user can't purchase without filling in the extra checkout field
    Given A buy sell product exist in current marketplace
    Given Extra fields are prepared
    When I search for buy sell "Product"
    Then I should see relevant buy sell products
    When I add buy sell product to cart
    Then The product should be included in my cart
    When I begin Checkout process
    When I fill in shippment details
    And  I choose shipping method
    Then I should see order summary page
    Then I should see the checkout extra fields
    When I fill billing data
    And  I shouldn't see order placed confirmation

  Scenario: A user can purchase if he filled in the extra checkout field
    Given A buy sell product exist in current marketplace
    Given Extra fields are prepared
    When I search for buy sell "Product"
    Then I should see relevant buy sell products
    When I add buy sell product to cart
    Then The product should be included in my cart
    When I begin Checkout process
    When I fill in shippment details
    And  I choose shipping method
    Then I should see order summary page
    Then I should see the checkout extra fields
    Then I fill in the extra checkout field
    When I fill billing data
    And  I should see order placed confirmation

  Scenario: A user can't purchase without filling in the extra checkout field mobile number
    Given A buy sell product exist in current marketplace
    Given Extra fields are prepared
    When I search for buy sell "Product"
    Then I should see relevant buy sell products
    When I add buy sell product to cart
    Then The product should be included in my cart
    When I begin Checkout process
    When I fill in shippment details
    And  I choose shipping method
    Then I should see order summary page
    Then I should see the checkout extra fields
    Then I fill in the extra checkout field without mobile number
    When I fill billing data
    And  I shouldn't see order placed confirmation

  Scenario: A user can't purchase without filling in the extra checkout field last name
    Given A buy sell product exist in current marketplace
    Given Extra fields are prepared
    When I search for buy sell "Product"
    Then I should see relevant buy sell products
    When I add buy sell product to cart
    Then The product should be included in my cart
    When I begin Checkout process
    When I fill in shippment details
    And  I choose shipping method
    Then I should see order summary page
    Then I should see the checkout extra fields
    Then I fill in the extra checkout field without last name
    When I fill billing data
    And  I shouldn't see order placed confirmation

  Scenario: A user from not supported country should not be able to buy product
    Given A buy sell product exist in current marketplace
    Given Instance without payment gateway defined
    When I search for buy sell "Product"
    Then I should see relevant buy sell products
    When I add buy sell product to cart
    Then The product should not be included in my cart

