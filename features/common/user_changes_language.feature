Feature: User changes language
  In order to view the Kassi UI in a different language
  As a person who speaks that language
  I want to be able to change language

  @javascript
  Scenario: User changes language without logging in
    Given I am on the home page
    When I follow "Offer something"
    And I follow "Home" 
    And I select "Finnish" from "locale"
    Then I should see "Tarjoa jotain" within "#offer_something_button"
  
  @javascript
  Scenario: User changes language when logged in
    Given I am logged in
    When I select "Finnish" from "locale"
    Then I should see "Tarjoa jotain" within "#offer_something_button"
  
  
  
  
  
  

    
  
