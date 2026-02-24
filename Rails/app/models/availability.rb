class Availability < ApplicationRecord
  belongs_to :available, polymorphic: true
  AVAILABLE_TYPES = %w[Category Item Table Combo].freeze
  MINIMUM_DURATION = 1.hour

  validates :start_at, presence: true
  validates :description, length: { maximum: 255 },
                          format: { without: /\A\s*\z/, message: "ne peut pas être composé uniquement d'espaces" }, allow_blank: true
  validates :available_type, presence: true, inclusion: { in: AVAILABLE_TYPES }
  validate :start_at_not_in_past
  validate :end_at_after_start_at
  validate :minimum_duration
  validate :no_overlapping_periods
  validate :available_not_deleted

  private

  def start_at_not_in_past
    return unless start_at.present?
    errors.add(:start_at, "doit être dans le futur") if start_at < Time.current.beginning_of_minute
  end

  def end_at_after_start_at
    return unless end_at.present? && start_at.present?
    errors.add(:end_at, "doit être après la date de début") if end_at < start_at
  end

  def minimum_duration
    return unless end_at.present? && start_at.present?
    if (end_at - start_at) < MINIMUM_DURATION
      errors.add(:end_at, "la durée minimale est de 1 heure")
    end
  end

  def available_not_deleted
    return unless available_id.present?

    record = case available_type
            when "Item"  then Item
            when "Table" then Table
            when "Combo" then Combo
            end

    return unless record

    unless record.exists?(id: available_id)
      errors.add(:base, "impossible de créer une disponibilité sur un élément archivé")
    end
  end

  def no_overlapping_periods
    return unless start_at.present? && end_at.present? && available_id.present? && available_type.present?

    overlaps = Availability.where(available_id: available_id, available_type: available_type)
                           .where.not(id: id)
                           .where("start_at < ? AND end_at > ?", end_at, start_at)

    errors.add(:base, "cette période chevauche une période existante") if overlaps.exists?
  end
end
