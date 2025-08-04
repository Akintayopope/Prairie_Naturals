class Coupon < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :discount_percentage, numericality: { greater_than: 0, less_than_or_equal_to: 100 }

  def self.ransackable_attributes(auth_object = nil)
    %w[id code discount_percentage created_at updated_at]
  end
end
