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

  def mark_cleaned!(cleaned_time: Time.current)
    transaction do
      update!(cleaned_at: cleaned_time)
      rotate_qr_if_needed!
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def rotate_qr_if_needed!
    return false unless qr_rotation_required?

    update!(
      temporary_code: SecureRandom.hex(16),
      qr_rotated_at: cleaned_at || Time.current
    )
  end

  private

  def qr_rotation_required?
    return false if cleaned_at.blank?
    return false if orders.where(ended_at: nil).exists?

    last_closed_order_at = orders.where.not(ended_at: nil).maximum(:ended_at)
    return false if last_closed_order_at.present? && cleaned_at <= last_closed_order_at
    return false if qr_rotated_at.present? && cleaned_at <= qr_rotated_at

    true
  end

  def cleaned_at_after_created_at
    return unless cleaned_at.present? && created_at.present?
    errors.add(:cleaned_at, "doit être après la date de création") if cleaned_at < created_at
  end

  def image_attached?
    image.attached?
  end
end
