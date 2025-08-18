describe('Cart & Checkout', () => {
  // Adjust to your routes
  const PRODUCTS_INDEX = '/products';
  const SUCCESS_URL = /\/checkout\/success|\/orders\/\d+/;

  it('Happy: add → update qty → checkout → success', () => {
    cy.visit(PRODUCTS_INDEX);
    cy.dc('product-card').first().click();

    cy.dc('add-to-cart').click();
    cy.dc('cart-link').click();

    cy.dc('cart-qty').clear().type('2');
    cy.dc('cart-update').click();
    cy.contains(/updated|cart/i).should('exist');

    // Stub your checkout session route if you redirect to Stripe
    cy.intercept('POST', '/checkout/sessions', (req) => {
      req.reply({ statusCode: 200, body: { redirect_url: '/checkout/success' } });
    }).as('createSession');

    cy.dc('checkout-btn').click();

    // Shipping page
    cy.dc('ship-name').type('Jane Doe');
    cy.dc('ship-address').type('123 Main St');
    cy.dc('ship-city').type('Winnipeg');
    cy.dc('ship-postal').type('R3C1A1');
    cy.dc('ship-country').select('Canada');

    cy.dc('place-order').click();

    // If your app would normally go to Stripe, you can directly visit success in test
    // cy.wait('@createSession'); cy.visit('/checkout/success');

    cy.url().should('match', SUCCESS_URL);
    cy.dc('order-success').should('contain', 'Thank you');
  });

  it('Unhappy: cannot checkout with empty cart', () => {
    cy.visit('/cart');
    cy.dc('checkout-btn').should('be.disabled');
  });

  it('Unhappy: quantity beyond stock shows error', () => {
    cy.visit(PRODUCTS_INDEX);
    cy.dc('product-card').first().click();
    cy.dc('add-to-cart').click();
    cy.dc('cart-link').click();

    cy.dc('cart-qty').clear().type('9999');
    cy.dc('cart-update').click();
    cy.dc('flash-error').should('be.visible');
  });

  it('Unhappy: missing shipping fields shows validation errors', () => {
    cy.visit(PRODUCTS_INDEX);
    cy.dc('product-card').first().click();
    cy.dc('add-to-cart').click();
    cy.dc('cart-link').click();
    cy.dc('checkout-btn').click();

    cy.dc('place-order').click(); // submit empty
    cy.dc('flash-error').should('be.visible');
  });
});
