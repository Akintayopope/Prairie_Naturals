class Category < ApplicationRecord
  has_many :products, dependent: :destroy

  validates :name, presence: true, uniqueness: true

   extend FriendlyId
  friendly_id :name, use: :slugged
end
