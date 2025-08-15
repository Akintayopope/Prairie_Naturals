describe('User Sign-In', () => {
  beforeEach(() => {
    // Visit the sign-in page
    cy.visit('/users/sign_in');
  });

  it('should sign in successfully with valid credentials', () => {
    cy.get('input[name="user[email]"]').type('test@example.com');
    cy.get('input[name="user[password]"]').type('password123', { log: false });
    cy.get('input[type="submit"], button[type="submit"]').click();

    // Expect to see a success message or be redirected
    cy.url().should('not.include', '/users/sign_in');
    cy.contains('Signed in successfully').should('exist');
  });

  it('should show an error with invalid credentials', () => {
    cy.get('input[name="user[email]"]').type('wrong@example.com');
    cy.get('input[name="user[password]"]').type('wrongpassword', { log: false });
    cy.get('input[type="submit"], button[type="submit"]').click();

    // Expect to see an error
    cy.contains('Invalid Email or password').should('exist');
    cy.url().should('include', '/users/sign_in');
  });
});
