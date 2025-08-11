# app/models/product.rb
class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  # Associations
  belongs_to :category, counter_cache: true, inverse_of: :products
  has_many   :order_items,    dependent: :restrict_with_error
  has_many   :reviews,        dependent: :destroy
  has_many   :cart_items,     dependent: :destroy
  has_many   :wishlist_items, dependent: :destroy

  has_many_attached :images

  # Normalization
  before_validation :normalize_name

  # Validations
  validates :category, presence: true
  validates :name,
            presence: true,
            length: { maximum: 200 },
            uniqueness: { case_sensitive: false }
  validates :price,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }
  validates :stock,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true

  # Scopes
  scope :alphabetical, -> { order(Arel.sql("LOWER(products.name) ASC")) }
  scope :in_stock,     -> { where("stock IS NULL OR stock > 0") }

  # FriendlyId: keep slug stable after creation
  def should_generate_new_friendly_id?
    slug.blank?
  end

  # Calculated fields
  def average_rating
    avg = reviews.average(:rating)
    avg ? avg.to_f.round(1) : 0.0
  end

  # Ransack whitelist (e.g., ActiveAdmin)
  def self.ransackable_associations(_ = nil)
    %w[category order_items reviews images_attachments images_blobs]
  end

  def self.ransackable_attributes(_ = nil)
    %w[
      id name slug title description price sale_price stock category_id
      rating image_url link created_at updated_at
    ]
  end

  private

  def normalize_name
    self.name = name.to_s.strip.squeeze(" ")
  end
end
