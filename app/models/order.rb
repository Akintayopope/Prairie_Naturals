class Order < ApplicationRecord
  belongs_to :user
  belongs_to :address
  has_many :order_items, dependent: :destroy

  # ✅ Valid statuses (enum-like)
  VALID_STATUSES = %w[pending paid processing shipped delivered cancelled]

  # ------------ Validations ------------
  validates :status,
            presence: true,
            inclusion: { in: VALID_STATUSES }

  validates :shipping_name,
            presence: true,
            length: { minimum: 2, maximum: 100 }

  validates :shipping_address,
            presence: true,
            length: { minimum: 5, maximum: 250 }

  validates :province, presence: true

  validates :subtotal, :tax, :total,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  # ------------ Defaults ------------
  after_initialize :set_default_status, if: :new_record?

  # ------------ Enum helper ------------
  def self.statuses
    VALID_STATUSES
  end

  # ------------ Ransack allowlists ------------
  def self.ransackable_associations(_ = nil)
    %w[address order_items user]
  end

  def self.ransackable_attributes(_ = nil)
    %w[id status total created_at user_id address_id shipping_name shipping_address province subtotal tax updated_at]
  end

  private

  def set_default_status
    self.status ||= "pending"
  end

  # ------------ Discord notifications ------------
  after_commit :notify_discord_on_create, on: :create

  def notify_discord_on_create
    DiscordNotifier.order_created(self)
  end
end
