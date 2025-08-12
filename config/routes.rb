Rails.application.routes.draw do
  # === Static redirects for legacy URLs ===
  get "/about",   to: redirect("/storefront/about"),   status: 301
  get "/contact", to: redirect("/storefront/contact"), status: 301

  # === Checkout ===
  resource :checkout, only: %i[new create], controller: "checkout" do
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
  resource :cart, only: :show, controller: "cart" do
    post   "add_item/:product_id",    to: "cart#add_item",          as: :add_item
    delete "remove_item/:product_id", to: "cart#remove_item",       as: :remove_item
    patch  "update_quantities",       to: "cart#update_quantities", as: :update_cart_quantities
  end

  # === Orders ===
  resources :orders, only: %i[index show]

  # === Storefront namespace (public-facing pages) ===
namespace :storefront do
  resources :products, only: %i[index show]

  # === Storefront static pages ===
  get  "about",             to: "static_pages#about",            as: :about
  get  "contact",           to: "static_pages#contact",          as: :contact
  post "contact",           to: "static_pages#contact_submit"

  # Shipping & returns
  get  "shipping-returns",  to: "static_pages#shipping_returns", as: :shipping_returns

  # Policies
  get  "store-policy",      to: "static_pages#store_policy",     as: :store_policy
  get  "policies",          to: "static_pages#store_policy",     as: :policies
  get  "policy",            to: redirect("/storefront/store-policy"), status: 301
  get  "policie",           to: redirect("/storefront/store-policy"), status: 301

  # Payments
  get  "payments",          to: "static_pages#payments",         as: :payments
  get  "payment-methods",   to: "static_pages#payments",         as: :payment_methods
  get  "payment",           to: "static_pages#payments"

  # FAQ, Privacy, Terms
  get  "faq",               to: "static_pages#faq",              as: :faq
  get  "privacy-policy",    to: "static_pages#privacy_policy",   as: :privacy_policy
  get  "terms",             to: "static_pages#terms",            as: :terms
end  # 👈 CLOSE namespace :storefront



  # === Authentication / Admin ===
  devise_for :users, controllers: { registrations: "users/registrations" }
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # === Catalog ===
  resources :products
  resources :categories, only: %i[index show]

  # === Root ===
  root "storefront/products#index"

  # === Health check ===
  get "up", to: "rails/health#show", as: :rails_health_check
end
