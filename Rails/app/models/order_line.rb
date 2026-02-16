class OrderLine < ApplicationRecord
  STATUSES = %w[sent in_preparation ready served].freeze
  STATUS_ORDER = STATUSES.each_with_index.to_h.freeze

  belongs_to :order
  belongs_to :orderable, polymorphic: true

  validates :quantity, presence: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 50 }
  validates :unit_price, presence: true,
                         numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 9999.99 }
  validates :note, length: { maximum: 255 },
                   format: { without: /\A\s*\z/, message: "ne peut pas être composé uniquement d'espaces" }, allow_blank: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :orderable_type, presence: true, inclusion: { in: %w[Item Combo] }
  validate :status_must_follow_sequence, if: :status_changed?
  validate :orderable_must_be_available
  validate :cannot_modify_unless_sent, on: :update

  private

  def status_must_follow_sequence   #le status doit suivre l'ordre séquentiel (sent → in_preparation → ready → served)
    return unless persisted? && status_was.present?
    old_index = STATUS_ORDER[status_was]
    new_index = STATUS_ORDER[status]
    return unless old_index && new_index
    errors.add(:status, "doit suivre l'ordre séquentiel (sent → in_preparation → ready → served)") if new_index != old_index + 1
  end

  def orderable_must_be_available  #l'item ou le combo référencé doit être disponible selon la table Availability
    return unless orderable_type.present? && orderable_id.present?
    unavailable = Availability.where(available_type: orderable_type, available_id: orderable_id)
                              .where("start_at <= ? AND (end_at IS NULL OR end_at >= ?)", Time.current, Time.current)
    errors.add(:orderable, "n'est pas disponible actuellement") if unavailable.exists?
  end

  def cannot_modify_unless_sent   #une ligne ne peut être supprimée/modifiée que si son status est 'sent'
    return unless status_was != "sent" && (quantity_changed? || note_changed? || orderable_id_changed?)
    errors.add(:base, "ne peut être modifiée que si son status est 'sent'")
  end
end
