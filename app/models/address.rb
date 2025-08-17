# app/models/address.rb
class Address < ApplicationRecord
  belongs_to :user
  belongs_to :province, optional: false   # ⬅️ require province
  has_many :orders

  # ---------- Normalization ----------
  before_validation :normalize_fields

  # ---------- Validations (kept yours + added detail) ----------
  validates :line1, :city, :postal_code, presence: true
  validates :province, presence: true     # ⬅️ extra clarity

  validates :line1, length: { maximum: 120 }
  validates :line2, length: { maximum: 120 }, allow_blank: true
  validates :city,  length: { maximum: 80 }

  # Canadian postal code: A1A 1A1 (space optional), excludes D,F,I,O,Q,U in letter slots
  POSTAL_CA = /\A[ABCEGHJ-NPRSTVXY]\d[ABCEGHJ-NPRSTV-Z][ -]?\d[ABCEGHJ-NPRSTV-Z]\d\z/i
  validates :postal_code, format: { with: POSTAL_CA, message: "must be a valid Canadian postal code (e.g., R3C 4T3)" }

  # Optional: basic city characters (letters, spaces, hyphens, apostrophes)
  validates :city, format: { with: /\A[ \p{L}\-']+\z/u,
                             message: "may only contain letters, spaces, hyphens, and apostrophes" }

  def full_address
    [ line1, line2, city, province&.name, postal_code ].compact.join(", ")
  end

  private

  def normalize_fields
    self.line1       = line1.to_s.strip
    self.line2       = line2.to_s.strip.presence
    self.city        = city.to_s.strip
    # Upcase and normalize postal code spacing to standard "A1A 1A1"
    pc = postal_code.to_s.strip.upcase.gsub(/\s+/, "")
    self.postal_code = pc.insert(3, " ") if pc.length == 6
  end
end
