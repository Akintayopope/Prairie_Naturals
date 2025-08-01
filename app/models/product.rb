class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :category
  has_many :order_items, dependent: :destroy
  has_many :reviews, dependent: :destroy

  has_one_attached :image

  # ✅ Allow safe searchable associations for ActiveAdmin/Ransack
  def self.ransackable_associations(auth_object = nil)
    ["category", "order_items", "reviews", "image_attachment", "image_blob"]
  end

  # ✅ Allow safe searchable fields/attributes
  def self.ransackable_attributes(auth_object = nil)
    ["id", "name", "slug", "description", "price", "stock", "title", "category_id", "created_at", "updated_at"]
  end
end
