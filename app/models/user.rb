class User < ApplicationRecord
  # Devise
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :province, optional: true

  # Associations
  has_many :orders, dependent: :destroy
  has_one  :address, dependent: :destroy, inverse_of: :user
  has_many :reviews, dependent: :destroy
  has_many :wishlist_items, dependent: :destroy
  has_many :cart_items, dependent: :destroy
  has_one_attached :avatar

  accepts_nested_attributes_for :address, update_only: true

  # Roles
  ROLES = %w[customer admin].freeze

  # ------------ Normalization (before validations) ------------
  before_validation :normalize_login_fields

  # ------------ Validations ------------
  # Devise :validatable already checks email presence/format/uniqueness (case-insensitive)
  validates :username,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { minimum: 3, maximum: 40 },
            format: {
              with: /\A[a-zA-Z0-9._-]+\z/,
              message: "may only contain letters, numbers, dot (.), underscore (_), and hyphen (-)"
            }

  validates :role,
            presence: true,
            inclusion: { in: ROLES }

  # Ensure nested address itself is valid when provided on create
  validates_associated :address, on: :create

  # Optional: avatar content validation (skip if you don't use avatars)
  validate :avatar_type_and_size

  # ------------ Helpers ------------
  def admin?    = role == "admin"
  def customer? = role == "customer"

  # Defaults
  after_initialize :set_default_role, if: :new_record?

  private

  def set_default_role
    self.role ||= "customer"
  end

  def normalize_login_fields
    self.email    = email.to_s.strip.downcase
    self.username = username.to_s.strip.squeeze(" ")
  end

  def avatar_type_and_size
    return unless avatar.attached?

    unless avatar.content_type.in?(%w[image/png image/jpg image/jpeg image/webp])
      errors.add(:avatar, "must be a PNG, JPG, JPEG, or WEBP")
    end
    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, "must be smaller than 5 MB")
    end
  end

  # Ransack allowlists
  def self.ransackable_attributes(_ = nil)
    %w[id email username created_at updated_at role]
  end

  def self.ransackable_associations(_ = nil)
    %w[address orders reviews wishlist_items cart_items]
  end
end
