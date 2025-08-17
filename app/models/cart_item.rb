class CartItem < ApplicationRecord
  belongs_to :user
  belongs_to :product

  # ------------ Validations ------------
  validates :quantity,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  # Optional safeguard: prevent duplicate cart items for same product/user
  validates :product_id, uniqueness: { scope: :user_id,
                                       message: "is already in your cart. Update the quantity instead." }
end
