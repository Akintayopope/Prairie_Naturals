# app/admin/users.rb

# Only register the resource if the table exists (prevents boot crashes on fresh DBs)
if (ActiveRecord::Base.connection.data_source_exists?(:users) rescue false)

  ActiveAdmin.register User do
    permit_params :email, :password, :password_confirmation, :role

    menu label: "Users", parent: "Users", priority: 2

    index do
      selectable_column
      id_column
      column :email
      column :role
      column :created_at
      actions
    end

    filter :email
    filter :role
    filter :created_at

    form do |f|
      f.inputs do
        f.input :email
        f.input :password
        f.input :password_confirmation
        # Use a lambda so nothing is evaluated at file load time
        f.input :role, as: :select, collection: -> { User::ROLES }
      end
      f.actions
    end

    controller do
      def update
        if params[:user][:password].blank?
          params[:user].delete(:password)
          params[:user].delete(:password_confirmation)
        end
        super
      end
    end
  end

else
  Rails.logger.warn("[activeadmin] Skipping User admin; users table not found yet.")
end
