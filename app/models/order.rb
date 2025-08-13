class Order < ApplicationRecord
  belongs_to :user
  belongs_to :address
  has_many :order_items, dependent: :destroy

  # ✅ Manually defined valid statuses
  VALID_STATUSES = %w[pending paid processing shipped delivered cancelled]

  # ✅ Validations
  validates :status, presence: true, inclusion: { in: VALID_STATUSES }
  validates :shipping_name, :shipping_address, :province, presence: true

  after_initialize :set_default_status, if: :new_record?

  # ✅ Manual replacement for enum-style helper
  def self.statuses
    VALID_STATUSES
  end

  # ✅ Ransack allowlist for associations
  def self.ransackable_associations(auth_object = nil)
    %w[address order_items user]
  end

  # ✅ (Optional) Ransack allowlist for attributes
  def self.ransackable_attributes(auth_object = nil)
    %w[id status total created_at user_id address_id shipping_name shipping_address province subtotal tax updated_at]
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
