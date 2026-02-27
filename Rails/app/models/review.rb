class Review < ApplicationRecord
  belongs_to :user
  belongs_to :reviewable, polymorphic: true

  has_many_attached :images

  validates :rating, presence: true,
                     numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :comment, presence: true, length: { maximum: 500 },
                      format: { without: /\A\s*\z/, message: "cannot consist only of whitespace" }
  validates :reviewable_type, presence: true, inclusion: { in: %w[Item Combo User] }
  validate :user_must_be_client
  validate :images_format_and_size
  validate :review_linked_to_ordered_item
  validate :review_linked_to_server

  default_scope { where(deleted_at: nil) }

  def soft_delete!
    update(deleted_at: Time.current)
  end

  def as_json(options = {})
    {
      id: id,
      user_id: user_id,
      user_name: user ? "#{user.first_name} #{user.last_name}" : nil,
      reviewable_type: reviewable_type,
      reviewable_id: reviewable_id,
      reviewable_name: compute_reviewable_name,
      rating: rating,
      comment: comment,
      image_urls: images.attached? ? images.map { |img| Rails.application.routes.url_helpers.rails_blob_url(img, only_path: true) } : [],
      created_at: created_at,
      updated_at: updated_at
    }
  end

  private

  def compute_reviewable_name
    return nil unless reviewable
    case reviewable_type
    when "User"
      "#{reviewable.first_name} #{reviewable.last_name}"
    else
      reviewable.name
    end
  end

  def user_must_be_client
    return unless user.present?
    errors.add(:user, "must be a client") unless user.type == "Client"
  end

  def images_format_and_size
    return unless images.attached?
    images.each do |img|
      unless img.content_type.in?(%w[image/jpeg image/png])
        errors.add(:images, "must be JPG or PNG files")
        break
      end
      if img.byte_size > 5.megabytes
        errors.add(:images, "must be less than 5 MB each")
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
    errors.add(:reviewable, "must be an item or combo the client has ordered") unless has_ordered
  end

  def review_linked_to_server
    return unless user.present? && reviewable_type == "User"
    reviewed_user = User.unscoped.find_by(id: reviewable_id)
    unless reviewed_user&.type == "Waiter"
      errors.add(:reviewable, "must be a waiter")
      return
    end
    served_by = Order.where(client_id: user_id, server_id: reviewable_id).exists?
    errors.add(:reviewable, "must have been the server on one of your orders") unless served_by
  end
end
