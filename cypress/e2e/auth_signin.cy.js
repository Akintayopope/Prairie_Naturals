import { faker } from '@faker-js/faker';

describe('User Sign-Up & Sign-In', () => {
  // Adjust these to your routes (Devise often uses /users/sign_up and /users/sign_in)
  const SIGNUP_PATH = '/signup';        // or '/users/sign_up'
  const LOGIN_PATH  = '/login';         // or '/users/sign_in'

  const email = `student+${Date.now()}@example.com`;
  const password = 'Password123!';

  it('Happy path: sign up, log out, then log back in', () => {
    cy.visit(SIGNUP_PATH);
    cy.dc('signup-email').type(email);
    cy.dc('signup-password').type(password);
    cy.dc('signup-password-confirm').type(password);
    cy.dc('signup-submit').click();

    cy.contains(/welcome|account|dashboard/i).should('exist');

    // logout then login
    cy.dc('nav-logout').click();
    cy.visit(LOGIN_PATH);
    cy.dc('login-email').type(email);
    cy.dc('login-password').type(password);
    cy.dc('login-submit').click();

    cy.contains(/welcome|account|dashboard/i).should('exist');
  });

  it('Unhappy path: bad sign-up shows validation errors', () => {
    cy.visit(SIGNUP_PATH);
    cy.dc('signup-email').type('not-an-email');
    cy.dc('signup-password').type('123');
    cy.dc('signup-password-confirm').type('321');
    cy.dc('signup-submit').click();
    cy.dc('flash-error').should('be.visible');
  });

  it('Unhappy path: wrong login password shows feedback', () => {
    cy.visit(LOGIN_PATH);
    cy.dc('login-email').type(email);
    cy.dc('login-password').type('WrongPass!1');
    cy.dc('login-submit').click();
    cy.dc('flash-error').should('be.visible');
  });
});
