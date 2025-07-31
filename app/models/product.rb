class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :category
  has_many :order_items, dependent: :destroy
  has_many :reviews, dependent: :destroy

  has_one_attached :image
end
