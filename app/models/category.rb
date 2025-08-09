# app/models/category.rb
class Category < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  # Associations
  has_many :products, dependent: :restrict_with_error, inverse_of: :category
  # Note: ensure categories.products_count exists if you're using counter_cache on Product

  # Normalization
  before_validation :normalize_name

  # Validations
  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { maximum: 100 }

  # Scopes
  scope :alphabetical, -> { order(Arel.sql('LOWER(name) ASC')) }

  # FriendlyId: regenerate slug when name changes
  def should_generate_new_friendly_id?
    will_save_change_to_name? || super
  end

  # Ransack (ActiveAdmin)
  def self.ransackable_attributes(_ = nil)
    %w[id name slug created_at updated_at products_count]
  end

  def self.ransackable_associations(_ = nil)
    %w[products]
  end

  private

  def normalize_name
    self.name = name.to_s.strip.squeeze(" ")
  end
end
