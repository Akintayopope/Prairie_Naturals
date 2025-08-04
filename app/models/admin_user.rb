class AdminUser < ApplicationRecord
  # Devise modules for authentication and account management.
  # Available modules include:
  # :confirmable, :lockable, :timeoutable, :trackable, and :omniauthable

  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable

  # Allow only specific attributes to be searchable in ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    %w[id email created_at updated_at]
  end
end
