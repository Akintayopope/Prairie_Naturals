class Coupon < ApplicationRecord
  enum :discount_type, { percent: 0, amount: 1 }

  before_validation { self.code = code.to_s.upcase.strip }

  validates :code, presence: true, uniqueness: true, length: { maximum: 32 }
  validates :discount_type, presence: true
  validates :value, presence: true

  # Percent coupons: 1–100
  with_options if: :percent? do
    validates :value,
              numericality: {
                greater_than_or_equal_to: 1,
                less_than_or_equal_to: 100
              }
  end

  # Amount coupons: >= 0.01
  with_options if: :amount? do
    validates :value, numericality: { greater_than_or_equal_to: 0.01 }
  end

  validates :max_uses,
            numericality: {
              greater_than_or_equal_to: 0
            },
            allow_nil: true

  scope :active_now,
        -> do
          now = Time.current
          where(
            "(starts_at IS NULL OR starts_at <= ?) AND (ends_at IS NULL OR ends_at >= ?) AND active = TRUE",
            now,
            now
          )
        end

  def active_now?
    active && (starts_at.nil? || starts_at <= Time.current) &&
      (ends_at.nil? || ends_at >= Time.current)
  end

  def usage_string
    "#{uses_count || 0} / #{max_uses || "∞"}"
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id
      code
      discount_type
      value
      max_uses
      uses_count
      active
      starts_at
      ends_at
      created_at
      updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i[active_now]
  end
end
