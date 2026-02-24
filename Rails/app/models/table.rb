class Table < ApplicationRecord
  has_many :orders
  has_many :availabilities, as: :available

  has_one_attached :image

  validates :number, presence: true, uniqueness: true,
                     numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 999 }
  validates :nb_seats, presence: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 20 }
  validates :temporary_code, uniqueness: true, allow_nil: true, length: { maximum: 50 }
  validates :image, content_type: { in: %w[image/jpeg image/png], message: "doit être un fichier JPG ou PNG" },
                    size: { less_than: 5.megabytes, message: "doit être inférieur à 5 MB" }, if: :image_attached?
  validate :cleaned_at_after_created_at

  default_scope { where(deleted_at: nil) }

  def soft_delete
    now = Time.current
    update(deleted_at: now)

    availabilities.where("start_at > ?", now).delete_all
    availabilities.where("start_at <= ? AND end_at > ?", now, now).update_all(end_at: now)
  end

  private

  def cleaned_at_after_created_at
    return unless cleaned_at.present? && created_at.present?
    errors.add(:cleaned_at, "doit être après la date de création") if cleaned_at < created_at
  end

  def image_attached?
    image.attached?
  end
end
