Rails.application.routes.draw do
  namespace :storefront do
    resources :products, only: [:index, :show]
  end

  resources :products, only: [:index, :show]
  resources :categories, only: [:index, :show]

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  # Optional: set public storefront as homepage
  # root "storefront/products#index"
end
