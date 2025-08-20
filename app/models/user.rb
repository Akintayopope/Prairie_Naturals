class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable
  belongs_to :province, optional: true

  ROLES = %w[customer admin].freeze

  # Associations
  has_many :orders, dependent: :destroy
  has_one :address, dependent: :destroy, inverse_of: :user # ⇦ add inverse_of
  has_many :reviews, dependent: :destroy
  has_many :wishlist_items, dependent: :destroy
  has_many :cart_items, dependent: :destroy
  has_one_attached :avatar

  accepts_nested_attributes_for :address, update_only: true

  # Validations
  validates :username, presence: true, uniqueness: true, length: { minimum: 3 }
  validates :role, inclusion: { in: ROLES }
  validates_associated :address, on: :create # ⇦ keep this

  def admin? = role == "admin"
  def customer? = role == "customer"

  after_initialize :set_default_role, if: :new_record?

  private

  def set_default_role
    self.role ||= "customer"
  end

  def self.ransackable_attributes(_ = nil)
    %w[id email username created_at updated_at role]
  end

  def self.ransackable_associations(_ = nil)
    %w[address orders reviews wishlist_items cart_items]
  end
end
