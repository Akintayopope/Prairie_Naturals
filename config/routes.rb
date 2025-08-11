Rails.application.routes.draw do
  # === Static redirects for legacy URLs ===
  get "/about",   to: redirect("/storefront/about"),   status: 301
  get "/contact", to: redirect("/storefront/contact"), status: 301

  # === Checkout ===
  resource :checkout, only: [:new, :create], controller: "checkout" do
    get :success
    get :cancel
    get :preview_receipt
  end

  # === API namespace ===
  namespace :api do
    get  "health_products",        to: "health_products#index"
    post "health_products/import", to: "health_products#import"
  end

  # === Cart ===
  resource :cart, only: [:show], controller: "cart" do
    post   "add_item/:product_id",    to: "cart#add_item",         as: :add_item
    delete "remove_item/:product_id", to: "cart#remove_item",      as: :remove_item
    patch  "update_quantities",       to: "cart#update_quantities", as: :update_cart_quantities
  end

  # === Orders ===
  resources :orders, only: [:index, :show]

  # === Storefront namespace (public-facing pages) ===
  namespace :storefront do
    resources :products, only: [:index, :show]

    # Static pages (controller: storefront/static_pages_controller)
    get  "about",            to: "static_pages#about"
    get  "contact",          to: "static_pages#contact"
    post "contact",          to: "static_pages#contact_submit"
    get  "shipping-returns", to: "static_pages#shipping_returns"
    get  "policies",         to: "static_pages#policies"
    get  "faq",              to: "static_pages#faq"
    get  "payments",         to: "static_pages#payments"
  end

  # === Devise auth ===
  devise_for :users, controllers: { registrations: "users/registrations" }
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # === Catalog ===
  resources :products
  resources :categories, only: [:index, :show]

  # === Root ===
  root "storefront/products#index"

  # === Health check ===
  get "up", to: "rails/health#show", as: :rails_health_check
end
