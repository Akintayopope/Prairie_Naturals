class Order < ApplicationRecord
  belongs_to :user
  belongs_to :address
  has_many :order_items, dependent: :destroy

  VALID_STATUSES = %w[pending paid processing shipped delivered cancelled]

  validates :status, presence: true, inclusion: { in: VALID_STATUSES }
  validates :shipping_name, :shipping_address, :province, presence: true

  after_initialize :set_default_status, if: :new_record?

  def self.statuses
    VALID_STATUSES
  end

  def self.ransackable_associations(auth_object = nil)
    %w[address order_items user]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[
      id
      status
      total
      created_at
      user_id
      address_id
      shipping_name
      shipping_address
      province
      subtotal
      tax
      updated_at
    ]
  end

  private

  def set_default_status
    self.status ||= "pending"
  end

  after_commit :notify_discord_on_create, on: :create

  private

  def notify_discord_on_create
    DiscordNotifier.order_created(self)
  end
end
