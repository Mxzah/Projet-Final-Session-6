class Review < ApplicationRecord
  belongs_to :user
  belongs_to :reviewable, polymorphic: true

  has_many_attached :images

  validates :rating, presence: true,
                     numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :comment, presence: true, length: { maximum: 500 },
                      format: { without: /\A\s*\z/, message: "ne peut pas être composé uniquement d'espaces" }
  validates :reviewable_type, presence: true, inclusion: { in: %w[Item Combo User] }
  validate :user_must_be_client
  validate :images_format_and_size
  validate :review_linked_to_ordered_item

  default_scope { where(deleted_at: nil) }

  def soft_delete
    update(deleted_at: Time.current)
  end

  private

  def user_must_be_client
    return unless user.present?
    errors.add(:user, "doit être un client") unless user.type == "Client"
  end

  def images_format_and_size
    return unless images.attached?
    images.each do |img|
      unless img.content_type.in?(%w[image/jpeg image/png])
        errors.add(:images, "doivent être des fichiers JPG ou PNG")
        break
      end
      if img.byte_size > 5.megabytes
        errors.add(:images, "doivent être inférieures à 5 MB chacune")
        break
      end
    end
  end

  def review_linked_to_ordered_item
    return unless user.present? && reviewable_type.in?(%w[Item Combo])
    has_ordered = OrderLine.joins(:order)
                           .where(orders: { client_id: user_id })
                           .where(orderable_type: reviewable_type, orderable_id: reviewable_id)
                           .exists?
    errors.add(:reviewable, "doit être un item ou combo que le client a commandé") unless has_ordered
  end
end
