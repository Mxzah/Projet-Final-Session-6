class Combo < ApplicationRecord
  has_many :combo_items
  has_many :items, through: :combo_items
  has_many :order_lines, as: :orderable
  has_many :reviews, as: :reviewable
  has_many :availabilities, as: :available

  has_one_attached :image

  validates :name, presence: true, length: { maximum: 100 }
  validate :name_not_only_whitespace
  validates :description, length: { maximum: 255 }
  validate :description_not_only_whitespace
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 9999.99 }
  validate :image_content_type_validation
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

  def name_not_only_whitespace
    if name.is_a?(String) && !name.empty? && name.strip.empty?
      errors.add(:name, :blank)
    end
  end

  def description_not_only_whitespace
    if description.is_a?(String) && !description.empty? && description.strip.empty?
      errors.add(:description, :invalid)
    end
  end

  def image_content_type_validation
    return unless image.attached?
    unless image.content_type.in?(%w[image/jpeg image/png])
      errors.add(:image, I18n.t('activerecord.errors.models.combo.attributes.image.invalid_content_type'))
    end
  end

  def image_size_validation
    return unless image.attached?
    if image.blob.byte_size > 5.megabytes
      errors.add(:image, I18n.t('activerecord.errors.models.combo.attributes.image.file_size_too_large'))
    end
  end
end
