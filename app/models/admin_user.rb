class AdminUser < ApplicationRecord
  # Devise modules for authentication and account management
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable

  # Allow searchable fields in ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    %w[id email current_sign_in_at sign_in_count created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
