Rails.application.routes.draw do
  get "orders/show"
  # Checkout
  resource :checkout, only: [:new, :create], controller: 'checkout'
  resources :orders, only: [:index, :show]


  # Cart controller using singular `resource`, since there's only one cart per session
  resource :cart, only: [:show], controller: 'cart' do
    post 'add_item/:product_id', to: 'cart#add_item', as: 'add_item'
    delete 'remove_item/:product_id', to: 'cart#remove_item', as: 'remove_item'
    patch 'update_quantities', to: 'cart#update_quantities', as: :update_cart_quantities
  end

  # Root path
  root "storefront/products#index"

  # Storefront namespace for public-facing product pages
  namespace :storefront do
    resources :products, only: [:index, :show]
  end

  # Admin and User authentication
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  # Product and category resources
  resources :products
  resources :categories, only: [:index, :show]

  # Health check route
  get "up" => "rails/health#show", as: :rails_health_check
end

