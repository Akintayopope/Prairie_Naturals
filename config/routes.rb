Rails.application.routes.draw do
  get "cart/show"
  get "cart/add_item"
  get "cart/remove_item"
  root "storefront/products#index" # Set root path to storefront products

  namespace :storefront do
    resources :products, only: [:index, :show]
  end

  resource :cart, only: [:show] do
  post 'add_item/:product_id', to: 'cart#add_item', as: 'add_item'
  delete 'remove_item/:product_id', to: 'cart#remove_item', as: 'remove_item'
 end


  resources :products
  resources :categories, only: [:index, :show]

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check
end
