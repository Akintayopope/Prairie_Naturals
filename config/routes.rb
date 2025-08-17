# config/routes.rb
Rails.application.routes.draw do
get "/debug/image_counts", to: "debug#image_counts"
  # === Health check ===
  get "up", to: "rails/health#show", as: :rails_health_check

  # === Legacy redirects (public)
  get "/about",   to: redirect("/storefront/about"),   status: 301
  get "/contact", to: redirect("/storefront/contact"), status: 301

  # === Auth (customers)
  devise_for :users, controllers: { registrations: "users/registrations" }

  # === Admin (mount only if DB is reachable and not disabled)
  if !(defined?(DISABLE_ADMIN) && DISABLE_ADMIN)
    begin
      if ActiveRecord::Base.connection.data_source_exists?(:users)
        # Ensure ActiveAdmin is configured with default_namespace = :internal
        devise_for :admin_users, ActiveAdmin::Devise.config.merge(path: "internal")
        ActiveAdmin.routes(self) # mounts under /internal
      else
        Rails.logger.warn("[AA] Skipping admin routes; users table not ready.")
      end
    rescue => e
      Rails.logger.warn("[AA] Skipping admin routes; DB not ready (#{e.class}).")
    end
  else
    Rails.logger.warn("[AA] Admin disabled (SAFE_MODE / DISABLE_ADMIN).")
  end

  # === Storefront (public)
  namespace :storefront do
    resources :products,   only: %i[index show]
    resources :categories, only: :show

    # Static pages
    get  "about",            to: "static_pages#about",            as: :about
    get  "contact",          to: "static_pages#contact",          as: :contact
    post "contact",          to: "static_pages#contact_submit"
    get  "shipping_returns", to: "static_pages#shipping_returns", as: :shipping_returns

    get  "store_policy",     to: "static_pages#store_policy",     as: :store_policy
    get  "policies",         to: "static_pages#store_policy",     as: :policies
    get  "policy",           to: redirect("/storefront/store-policy"), status: 301
    get  "policie",          to: redirect("/storefront/store-policy"), status: 301

    get  "payments",         to: "static_pages#payments",         as: :payments
    get  "payment-methods",  to: "static_pages#payments",         as: :payment_methods
    get  "payment",          to: "static_pages#payments"

    get  "faq",              to: "static_pages#faq",              as: :faq
    get  "privacy-policy",   to: "static_pages#privacy_policy",   as: :privacy_policy
    get  "terms",            to: "static_pages#terms",            as: :terms
  end

  # === Cart (session-based, public)
  resource :cart, only: :show, controller: "cart" do
    post   "add_item/:product_id",    to: "cart#add_item",          as: :add_item
    delete "remove_item/:product_id", to: "cart#remove_item",       as: :remove_item
    patch  "update_quantities",       to: "cart#update_quantities", as: :update_cart_quantities
  end

  # === Orders (read-only history pages)
  resources :orders, only: %i[index show] do
    member { post :pay, to: "checkout#pay" }
  end

  # === Checkout (protected in controller)
  resource :checkout, only: %i[new create], controller: "checkout" do
    get :success
    get :cancel
    get :preview_receipt
  end

  # === API
  namespace :api do
    get  "health_products",        to: "health_products#index"
    post "health_products/import", to: "health_products#import"
  end

  # (Optional) If you want /categories/:id as a public alias to the storefront page:
  # get "/categories/:id", to: "storefront/categories#show", as: :category

  # === Root (public)
  root to: "storefront/products#index"


end
