class Order < ApplicationRecord
  belongs_to :user
  belongs_to :address
  has_many :order_items, dependent: :destroy

  enum status: {
    pending: 0,
    paid: 1,
    processing: 2,
    shipped: 3,
    delivered: 4,
    cancelled: 5
  }

  validates :status, presence: true
  validates :shipping_name, :shipping_address, :province, presence: true

  after_initialize :set_default_status, if: :new_record?

  private

  def set_default_status
    self.status ||= :pending
  end
end
