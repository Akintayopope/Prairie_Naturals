class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Constants for role management
  ROLES = %w[customer admin].freeze

  # Associations
  has_many :orders, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :wishlist_items, dependent: :destroy
  has_one_attached :avatar
  has_many :cart_items, dependent: :destroy

  # Role validation
  validates :role, inclusion: { in: ROLES }

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

  def self.ransackable_attributes(auth_object = nil)
    %w[id email created_at updated_at role] # Only include what you want searchable
  end

  def self.ransackable_associations(auth_object = nil)
  []
end

end
