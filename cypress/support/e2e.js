import "@testing-library/cypress/add-commands";

// UI helper for Devise login via the form
Cypress.Commands.add("loginUI", (email, password) => {
  cy.visit("/users/sign_in");
  cy.findByTestId("email").clear().type(email);
  cy.findByTestId("password").clear().type(password);
  cy.findByTestId("submit").click();
});
