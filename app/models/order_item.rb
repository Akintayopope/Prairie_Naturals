class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product


  validates :quantity, numericality: { greater_than: 0 }
  def self.ransackable_attributes(auth_object = nil)
    [ "id", "order_id", "product_id", "quantity", "unit_price", "created_at", "updated_at" ]
  end
end
