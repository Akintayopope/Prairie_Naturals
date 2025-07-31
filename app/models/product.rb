class Product < ApplicationRecord
  belongs_to :category
  has_many :order_items, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :wishlist_items, dependent: :destroy
  has_one_attached :image

  validates :name, :price, :stock_quantity, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
end
