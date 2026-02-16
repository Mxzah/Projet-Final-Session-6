class Category < ApplicationRecord
  has_many :items, dependent: :restrict_with_error
  has_many :availabilities, as: :available

  validates :name, presence: true, uniqueness: true, length: { maximum: 100 },
                   format: { without: /\A\s*\z/, message: "ne peut pas être composé uniquement d'espaces" }
  validates :position, presence: true, uniqueness: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
