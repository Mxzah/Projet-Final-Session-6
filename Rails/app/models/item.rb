class Item < ApplicationRecord
  belongs_to :category
  has_many :combo_items
  has_many :combos, through: :combo_items
  has_many :order_lines, as: :orderable
  has_many :reviews, as: :reviewable
  has_many :availabilities, as: :available

  has_one_attached :image

  validates :name, presence: true, length: { maximum: 100 },
                   format: { without: /\A\s*\z/, message: "ne peut pas être composé uniquement d'espaces" }
  validates :description, length: { maximum: 255 },
                          format: { without: /\A\s*\z/, message: "ne peut pas être composé uniquement d'espaces" }, allow_blank: true
  validates :price, presence: true,
                    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 9999.99 }
  validate :image_presence
  validates :image, content_type: { in: %w[image/jpeg image/png], message: "doit être un fichier JPG ou PNG" },
                    size: { less_than: 5.megabytes, message: "doit être inférieur à 5 MB" }, if: :image_attached?

  default_scope { where(deleted_at: nil) }

  def soft_delete
    update(deleted_at: Time.current)
  end

  private

  def image_presence
    errors.add(:image, "est obligatoire") unless image.attached?
  end

  def image_attached?
    image.attached?
  end
end
