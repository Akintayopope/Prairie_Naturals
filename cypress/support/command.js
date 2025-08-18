// Find by data-cy (use data-cy attributes in your views)
Cypress.Commands.add('dc', (selector) => cy.get(`[data-cy=${selector}]`));
