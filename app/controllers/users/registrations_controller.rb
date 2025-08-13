# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  # Your app no longer defines a global authenticate_user!,
  # so make this skip tolerant (or remove it entirely).
  skip_before_action :authenticate_user!, only: [:new, :create], raise: false

  # Provide provinces for the form and re-render on errors
  before_action :set_provinces, only: [:new, :create]

  # Prebuild an address for the form
  def new
    super do |resource|
      resource.build_address unless resource.address
    end
  end

  # Let Devise handle create with permitted params defined in ApplicationController.
  # You don't need to override #create unless you have custom side effects.
  # If you ever need to, call `super` and keep @provinces for re-render.

  protected

  # After sign up, land on the storefront
  def after_sign_up_path_for(_resource)
    root_path
  end

  private

  def set_provinces
    @provinces =
      if defined?(Province) && Province.respond_to?(:order) && Province.column_names.include?("name")
        Province.order(:name)
      else
        [] # view will gracefully fall back if empty
      end
  end
end
