class Coupon < ApplicationRecord
  enum :discount_type, { percent: 0, amount: 1 }

  before_validation { self.code = code.to_s.upcase.strip }

  # ---- Validations ----
  validates :code,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { maximum: 32 },
            format: { with: /\A[A-Z0-9\-]+\z/,
                      message: "may only contain letters, numbers, and hyphens" }

  validates :discount_type, presence: true
  validates :value, presence: true, numericality: true

  # Percent coupons: 1–100
  with_options if: :percent? do
    validates :value, numericality: {
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 100
    }
  end

  # Amount coupons: >= 0.01
  with_options if: :amount? do
    validates :value, numericality: {
      greater_than_or_equal_to: 0.01
    }
  end

  validates :max_uses, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :uses_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  validate  :ends_after_starts
  validate  :not_overused

  scope :active_now, -> {
    now = Time.current
    where("(starts_at IS NULL OR starts_at <= ?) AND (ends_at IS NULL OR ends_at >= ?) AND active = TRUE", now, now)
  }

  def active_now?
    active && (starts_at.nil? || starts_at <= Time.current) && (ends_at.nil? || ends_at >= Time.current)
  end

  def usage_string
    "#{uses_count || 0} / #{max_uses || '∞'}"
  end

  # 🔎 Ransack 4 allowlists
  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id code discount_type value max_uses uses_count active
      starts_at ends_at created_at updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i[active_now]
  end

  private

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank?
    errors.add(:ends_at, "must be after starts_at") if ends_at < starts_at
  end

  def not_overused
    return if max_uses.blank? || uses_count.blank?
    if uses_count > max_uses
      errors.add(:uses_count, "cannot exceed max_uses")
    end
  end
end
