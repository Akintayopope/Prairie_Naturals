class StaticPage < ApplicationRecord
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  def self.ransackable_attributes(_ = nil)
    %w[id title slug body created_at updated_at]
  end

  def self.ransackable_associations(_ = nil)
    []
  end
end
