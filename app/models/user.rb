class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Constants for role management
  ROLES = %w[customer admin].freeze

  # Role checks
  def admin?
    role == 'admin'
  end

  def customer?
    role == 'customer'
  end

  # Default role assignment
  after_initialize :set_default_role, if: :new_record?

  private

  def set_default_role
    self.role ||= 'customer'
  end
end
