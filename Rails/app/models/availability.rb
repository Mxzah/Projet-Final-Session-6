class Availability < ApplicationRecord
  AVAILABLE_TYPES = %w[Category Item Table Combo].freeze
  MINIMUM_DURATIONS = {
    "Category" => 1.hour,
    "Item" => 30.minutes,
    "Combo" => 30.minutes,
    "Table" => 15.minutes
  }.freeze

  belongs_to :available, polymorphic: true

  validates :start_at, presence: true
  validates :description, length: { maximum: 255 },
                          format: { without: /\A\s*\z/, message: "ne peut pas être composé uniquement d'espaces" }, allow_blank: true
  validates :available_type, presence: true, inclusion: { in: AVAILABLE_TYPES }
  validate :end_at_after_start_at
  validate :minimum_duration

  private

  def end_at_after_start_at
    return unless end_at.present? && start_at.present?
    errors.add(:end_at, "doit être après la date de début") if end_at < start_at
  end

  def minimum_duration
    return unless end_at.present? && start_at.present? && available_type.present?
    min = MINIMUM_DURATIONS[available_type]
    return unless min
    if (end_at - start_at) < min
      errors.add(:end_at, "la durée minimale pour #{available_type} est de #{min.inspect}")
    end
  end
end
