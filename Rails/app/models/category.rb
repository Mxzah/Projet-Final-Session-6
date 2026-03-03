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

    # Décaler toutes les catégories à cette position ou après
    shift_scope = self.class.where("position >= ?", position)
    shift_scope = shift_scope.where.not(id: id) if persisted?
    shift_scope.order(position: :desc).each do |cat|
      cat.update_column(:position, cat.position + 1)
    end
  end

  def cleanup_availabilities
    now = Time.current
    availabilities.where("start_at > ?", now).delete_all
    availabilities.where("start_at <= ? AND end_at > ?", now, now).update_all(end_at: now)
  end
end
