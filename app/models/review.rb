class Review < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :rating, inclusion: { in: 1..5 }
  validates :comment, presence: true

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "comment", "rating", "product_id", "user_id", "created_at", "updated_at" ]
  end
end
