# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :authenticate_user!, only: [:new, :create], raise: false
  before_action :set_provinces, only: [:new, :create, :edit, :update]
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  def new
    super do |resource|
      resource.build_address unless resource.address
    end
  end

  protected

  def after_sign_up_path_for(_resource)
    root_path
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(
      :sign_up,
      keys: [
        :username,
        { address_attributes: [:line1, :line2, :city, :province_id, :postal_code] }
      ]
    )
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(
      :account_update,
      keys: [
        :username,
        { address_attributes: [:id, :line1, :line2, :city, :province_id, :postal_code] }
      ]
    )
  end

  private

  def set_provinces
    @provinces =
      if defined?(Province) && Province.respond_to?(:order) && Province.column_names.include?("name")
        Province.order(:name)
      else
        []
      end
  end
end
