class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :authenticate_user!, only: [:new, :create]

  def new
    build_resource
    resource.build_address unless resource.address
    super
  end

  def create
    build_resource(sign_up_params)
    resource.build_address unless resource.address
    resource.address.assign_attributes(address_params)

    if resource.save
      sign_up(resource_name, resource)
      respond_with resource, location: after_sign_up_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  protected

  def address_params
    params.fetch(:user, {}).fetch(:address_attributes, {}).permit(:line1, :line2, :city, :postal_code, :province_id)
  end
end
