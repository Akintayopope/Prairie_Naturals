ActiveAdmin.register AdminUser do
  permit_params :email, :password, :password_confirmation

  menu label: "Admin Users", priority: 1, parent: "Users"

  index title: "Admin Users" do
    selectable_column
    id_column
    column :email
    column("Last Sign-In", :current_sign_in_at)
    column("Sign-Ins", :sign_in_count)
    column("Created At", :created_at)
    actions defaults: true do |admin_user|
      item "Reset Password", reset_password_admin_admin_user_path(admin_user),
           method: :put, class: "member_link"
    end
  end

  filter :email
  filter :current_sign_in_at, label: "Last Login"
  filter :sign_in_count, label: "Login Count"
  filter :created_at

  show title: proc { |admin_user| "Admin User ##{admin_user.id}" } do
    attributes_table do
      row :id
      row :email
      row :current_sign_in_at
      row :sign_in_count
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  form do |f|
    f.semantic_errors
    f.inputs "Admin User Details" do
      f.input :email
      f.input :password, input_html: { autocomplete: "new-password" }
      f.input :password_confirmation, input_html: { autocomplete: "new-password" }
    end
    f.actions
  end

  member_action :reset_password, method: :put do
    new_password = SecureRandom.hex(6)
    resource.update(password: new_password, password_confirmation: new_password)
    redirect_to resource_path, notice: "Password reset. New temporary password: #{new_password}"
  end
end
