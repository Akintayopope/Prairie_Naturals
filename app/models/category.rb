class Category < ApplicationRecord
  has_many :products, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  extend FriendlyId
  friendly_id :name, use: :slugged

  def self.ransackable_attributes(auth_object = nil)
    %w[id name slug created_at updated_at]
  end
end
