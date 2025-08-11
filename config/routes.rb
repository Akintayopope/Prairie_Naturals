Rails.application.routes.draw do
  get "/about",   to: "static_pages#show", defaults: { slug: "about" },   as: :about
  get "/contact", to: "static_pages#show", defaults: { slug: "contact" }, as: :contact

  get "orders/show"
# config/routes.rb
resource :checkout, only: [ :new, :create ], controller: "checkout" do
  get :success
  get :cancel
  get :preview_receipt
end


# config/routes.rb
namespace :api do
  get  "health_products",        to: "health_products#index"
  post "health_products/import", to: "health_products#import"
end

  # Cart controller using singular `resource`, since there's only one cart per session
  resource :cart, only: [ :show ], controller: "cart" do
    post "add_item/:product_id", to: "cart#add_item", as: "add_item"
    delete "remove_item/:product_id", to: "cart#remove_item", as: "remove_item"
    patch "update_quantities", to: "cart#update_quantities", as: :update_cart_quantities
  end

  # Root path
  root "storefront/products#index"
  resources :orders, only: [ :index, :show ]

  # Storefront namespace for public-facing product pages
  namespace :storefront do
    resources :products, only: [ :index, :show ]
  end
  devise_for :users, controllers: { registrations: "users/registrations" }

  # Admin and User authentication
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # Product and category resources
  resources :products
  resources :categories, only: [ :index, :show ]

  # Health check route
  get "up" => "rails/health#show", as: :rails_health_check
end
