# app/models/category.rb
# frozen_string_literal: true

class Category < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  # --- Constants ---
VALID_CATEGORY_NAMES = [
  "Vitamins",
  "Protein Supplements",
  "Digestive Health",
  "Skin Care",
  "Hair Care"
].freeze

  # --- Associations ---
  has_many :products, dependent: :restrict_with_error, inverse_of: :category
  # If you add counter cache:
  # has_many :products, dependent: :restrict_with_error, inverse_of: :category
  # (and add products_count column + counter_cache: true on Product)

  # --- Callbacks ---
  before_validation :normalize_name!

  # --- Validations ---
  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { maximum: 100 },
            inclusion: { in: VALID_CATEGORY_NAMES,
                         message: "must be one of: #{VALID_CATEGORY_NAMES.join(', ')}" }

  # --- Scopes ---
  scope :alphabetical, -> { order(Arel.sql('LOWER(name) ASC')) }
  scope :defaults,     -> { where(name: VALID_CATEGORY_NAMES) }

  # --- FriendlyId ---
  def should_generate_new_friendly_id?
    will_save_change_to_name? || super
  end

  # --- Ransack (ActiveAdmin) ---
  def self.ransackable_attributes(_ = nil)
    %w[id name slug created_at updated_at products_count]
  end

  def self.ransackable_associations(_ = nil)
    %w[products]
  end

  # --- Utilities ---
  # Seed helper you can call from seeds: Category.ensure_default_set!
  def self.ensure_default_set!
    VALID_CATEGORY_NAMES.each { |n| find_or_create_by!(name: n) }
  end

  private

  def normalize_name!
    self.name = name.to_s.strip.squeeze(" ")
                      .gsub(/\s+/, " ")
                      .split.map(&:capitalize).join(" ")
  end
end
