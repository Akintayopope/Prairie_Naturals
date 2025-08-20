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
      ns = ActiveAdmin.application.default_namespace
      helper = :"reset_password_#{ns}_admin_user_path"

      if helpers.respond_to?(helper)
        item "Reset Password",
             send(helper, admin_user),
             method: :put,
             class: "member_link",
             data: {
               turbo: false,
               confirm: "Send reset instructions to #{admin_user.email}?"
             }
      end
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
      f.input :password_confirmation,
              input_html: {
                autocomplete: "new-password"
              }
    end
    f.actions
  end

  # Safer: send Devise reset instructions (requires :recoverable on AdminUser)
  member_action :reset_password, method: :put do
    resource.send_reset_password_instructions
    redirect_to resource_path,
                notice: "Password reset email sent to #{resource.email}."
  end
end
