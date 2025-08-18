# config/routes.rb
Rails.application.routes.draw do
  # === Health check ===
  get "up", to: "rails/health#show", as: :rails_health_check

  # === Legacy redirects ===
  get "/about",   to: redirect("/storefront/about"),   status: 301
  get "/contact", to: redirect("/storefront/contact"), status: 301

  # === Auth (customers) ===
  devise_for :users, controllers: { registrations: "users/registrations" }

  # === Admin auth + admin UI under /internal ===
  # ActiveAdmin::Devise.config picks up the namespace; we also merge the path to be explicit.
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)  # will mount under /internal because of config.default_namespace

  # === Storefront (public) ===
  namespace :storefront do
    resources :products,   only: %i[index show]
    resources :categories, only: %i[show]
    post "/stripe/webhook", to: "stripe/webhooks#create"


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

  # === Cart (session-based, public) ===
  resource :cart, only: :show, controller: "cart" do
    post   "add_item/:product_id",    to: "cart#add_item",          as: :add_item
    delete "remove_item/:product_id", to: "cart#remove_item",       as: :remove_item
    patch  "update_quantities",       to: "cart#update_quantities", as: :update_cart_quantities
  end

  # === Orders (read-only history pages) ===
  resources :orders, only: %i[index show] do
  member do
    get  :receipt        # <- needed for the PDF link
    post :pay, to: "checkout#pay"
  end
end
get "checkout/success", to: "checkout#success"

  # === Checkout (protected in controller via before_action :authenticate_user!) ===
  resource :checkout, only: %i[new create], controller: "checkout" do
    get :success
    get :cancel
    get :preview_receipt
  end

  def receipt
  @order = current_user.orders.find(params[:id])

  respond_to do |format|
    format.html { render :receipt }  # test this first: /orders/:id/receipt
    format.pdf  do                   # then /orders/:id/receipt.pdf
      render pdf: "Receipt-#{@order.id}",
             template: "orders/receipt",
             layout: "pdf",          # remove this if you don't have app/views/layouts/pdf.html.erb
             disposition: "attachment"
    end
  end
end


  # === API ===
  namespace :api do
    get  "health_products",        to: "health_products#index"
    post "health_products/import", to: "health_products#import"
  end

  # === Public catalog endpoints (optional) ===
  resources :categories, only: %i[index show]

  # === Root (public) ===
  root to: "storefront/products#index"
end
