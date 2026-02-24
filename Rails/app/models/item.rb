class Item < ApplicationRecord
  belongs_to :category
  has_many :combo_items
  has_many :combos, through: :combo_items
  has_many :order_lines, as: :orderable
  has_many :reviews, as: :reviewable
  has_many :availabilities, as: :available

  has_one_attached :image

  validates :name, presence: true, length: { maximum: 100 },
                   format: { without: /\A\s*\z/, message: "cannot be only whitespace" }
  validates :description, length: { maximum: 255 },
                          format: { without: /\A\s*\z/, message: "cannot be only whitespace" }, allow_blank: true
  validates :price, presence: true,
                    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 9999.99 }
  validate :image_presence
  validate :deleted_at_must_be_now
  validates :image, content_type: { in: %w[image/jpeg image/png], message: "must be a JPG or PNG file" },
                    size: { less_than: 5.megabytes, message: "must be less than 5 MB" }, if: :image_attached?

  default_scope { where(deleted_at: nil) }

  def soft_delete!
    now = Time.current
    update(deleted_at: now)

    availabilities.where("start_at > ?", now).delete_all
    availabilities.where("start_at <= ? AND end_at > ?", now, now).update_all(end_at: now)

    self
  end

  private

  def image_presence
    errors.add(:image, "is required") unless image.attached?
  end

  def image_attached?
    image.attached?
  end

  def deleted_at_must_be_now
    return if deleted_at.nil?
    return unless deleted_at_changed?

    if (deleted_at - Time.current).abs > 5.seconds
      errors.add(:deleted_at, "must be the current time")
    end
  end
end
