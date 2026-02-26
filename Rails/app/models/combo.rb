class Combo < ApplicationRecord
  has_many :combo_items
  has_many :items, through: :combo_items
  has_many :order_lines, as: :orderable
  has_many :reviews, as: :reviewable
  has_many :availabilities, as: :available

  has_one_attached :image

  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 255 }
  validates :price, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 9999.99 }
  validate :image_size_validation

  default_scope { where(deleted_at: nil) }

  def soft_delete!
    now = Time.current
    update(deleted_at: now)

    availabilities.where("start_at > ?", now).delete_all
    availabilities.where("start_at <= ? AND end_at > ?", now, now).update_all(end_at: now)

    self
  end

  private

  def image_size_validation
    return unless image.attached?
    if image.blob.byte_size > 5.megabytes
      errors.add(:image, I18n.t('activerecord.errors.models.combo.attributes.image.file_size_too_large'))
    end
  end
end
