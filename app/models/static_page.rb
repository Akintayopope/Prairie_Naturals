class StaticPage < ApplicationRecord
  validates :title, presence: true
  validates :slug,  presence: true, uniqueness: true

  # Allow these fields to be searched/filtered in ActiveAdmin
  def self.ransackable_attributes(_ = nil)
    %w[id title slug body created_at updated_at]
  end
end
