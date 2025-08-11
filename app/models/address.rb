# app/models/address.rb
class Address < ApplicationRecord
  belongs_to :user
  belongs_to :province, optional: false   # ⬅️ require province
  has_many :orders

  validates :line1, :city, :postal_code, presence: true
  validates :province, presence: true     # ⬅️ extra clarity

  def full_address
    [ line1, line2, city, province&.name, postal_code ].compact.join(", ")
  end
end
