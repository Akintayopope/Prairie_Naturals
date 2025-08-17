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

  # ---- Validations (ADDED) ----
  validates :category, presence: true
  validates :name,  presence: true,
                    uniqueness: { case_sensitive: false },
                    length: { maximum: 200 }

  validates :description, length: { maximum: 2000 }, allow_blank: true

  validates :price,      presence: true,
                         numericality: { greater_than_or_equal_to: 0 }

  validates :sale_price, numericality: { greater_than_or_equal_to: 0 },
                         allow_nil: true

  validate  :sale_price_not_greater_than_price

  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  validate  :images_types_and_sizes   # optional but helpful

  # Scopes
  scope :alphabetical, -> { order(Arel.sql("LOWER(name) ASC")) }
  scope :in_stock,     -> { where("stock IS NULL OR stock > 0") }

  # FriendlyId: refresh slug when name changes
  def should_generate_new_friendly_id?
    will_save_change_to_name? || super
  end

  # Average rating computed from reviews
  def average_rating
    avg = reviews.average(:rating)
    avg ? avg.to_f.round(1) : 0.0
  end

  def display_rating
    (self.rating.presence || average_rating.to_f).to_f
  end

  # Prefer our own DB counter if present, else the imported CSV count
  def total_reviews
    (self.reviews_count.presence || self.review_count.to_i)
  end

  # Ransack (ActiveAdmin)
  # (CONSOLIDATED into a single method)
  def self.ransackable_associations(_ = nil)
    %w[category order_items reviews images_attachments images_blobs]
  end

  def self.ransackable_attributes(_ = nil)
    %w[
      id name slug title description price sale_price stock category_id
      rating image_url link reviews_count review_count created_at updated_at
    ]
  end

  private

  def normalize_name
    self.name = name.to_s.strip.squeeze(" ")
  end

  # ---- Custom validations ----
  def sale_price_not_greater_than_price
    return if sale_price.blank? || price.blank?
    if sale_price > price
      errors.add(:sale_price, "cannot be greater than price")
    end
  end

  def images_types_and_sizes
    return unless images.attached?
    images.each do |img|
      unless img.content_type.in?(%w[image/png image/jpg image/jpeg image/webp])
        errors.add(:images, "must be PNG, JPG, JPEG, or WEBP")
      end
      if img.byte_size > 8.megabytes
        errors.add(:images, "must be smaller than 8 MB each")
      end
    end
  end
end
