class Category < ApplicationRecord
  has_many :items, dependent: :restrict_with_error
  has_many :availabilities, as: :available

  before_destroy :cleanup_availabilities
  before_validation :reorder_positions, if: :position_changed?

  validates :name, presence: true, uniqueness: true, length: { maximum: 100 },
                   format: { without: /\A\s*\z/, message: "ne peut pas être composé uniquement d'espaces" }
  validates :position, presence: true, uniqueness: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  private

  def reorder_positions
    return unless position.present?

    scope = self.class.where(position: position)
    scope = scope.where.not(id: id) if persisted?
    return unless scope.exists?

    offset = self.class.maximum(:position).to_i + 1000

    # Déplacer le record courant vers une position temporaire pour libérer l'espace
    self.class.where(id: id).update_all(position: offset + 999) if persisted?

    # Décaler toutes les catégories à cette position ou après
    shift_scope = self.class.where("position >= ? AND position < ?", position, offset)
    shift_scope = shift_scope.where.not(id: id) if persisted?
    shift_scope.update_all("position = position + #{offset}")

    # Remettre les positions décalées à +1 de leur position originale
    self.class.where("position >= ?", offset).where.not(id: id).update_all("position = position - #{offset} + 1")
  end

  def cleanup_availabilities
    now = Time.current
    availabilities.where("start_at > ?", now).delete_all
    availabilities.where("start_at <= ? AND end_at > ?", now, now).update_all(end_at: now)
  end
end
