Rails.application.routes.draw do
  root "storefront/products#index" # Set root path to storefront products

  namespace :storefront do
    resources :products, only: [:index, :show]
  end

  resources :products
  resources :categories, only: [:index, :show]

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check
end
