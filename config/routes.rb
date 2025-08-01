Rails.application.routes.draw do
  namespace :storefront do
    resources :products, only: [:index, :show]
  end

  resources :products # ← full RESTful routes including edit
  resources :categories, only: [:index, :show]

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  # root "storefront/products#index"
end
