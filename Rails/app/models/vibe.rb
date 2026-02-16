class Vibe < ApplicationRecord
  has_many :orders

  has_one_attached :image

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 },
                   format: { without: /\A\s*\z/, message: "ne peut pas être composé uniquement d'espaces" }
  validates :color, presence: true, length: { maximum: 7 },
                    format: { without: /\A\s*\z/, message: "ne peut pas être composé uniquement d'espaces" }
  validates :image, content_type: { in: %w[image/jpeg image/png], message: "doit être un fichier JPG ou PNG" },
                    size: { less_than: 5.megabytes, message: "doit être inférieur à 5 MB" }, if: :image_attached?

  default_scope { where(deleted_at: nil) }

  def soft_delete
    update(deleted_at: Time.current)
  end

  private

  def image_attached?
    image.attached?
  end
end
