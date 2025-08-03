class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :category
  has_many :order_items, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :cart_items
  has_many_attached :images  # <-- updated here

  def average_rating
    return 0 if reviews.empty?
    reviews.average(:rating).round(1)
  end

  # ✅ Allow safe searchable associations for ActiveAdmin/Ransack
  def self.ransackable_associations(auth_object = nil)
    ["category", "order_items", "reviews", "images_attachments", "images_blobs"]
  end

  # ✅ Allow safe searchable fields/attributes
  def self.ransackable_attributes(auth_object = nil)
    ["id", "name", "slug", "description", "price", "stock", "title", "category_id", "created_at", "updated_at"]
  end
end
