# frozen_string_literal: true

# Customer review for items, combos, or orders
class Review < ApplicationRecord
  belongs_to :user
  belongs_to :reviewable, polymorphic: true
  belongs_to :order, optional: true

  has_many_attached :images

  validates :rating, presence: true,
                     numericality: {
                       only_integer: true,
                       greater_than_or_equal_to: 1,
                       less_than_or_equal_to: 5
                     }
  validates :comment, length: { maximum: 500 }, allow_blank: true
  validates :reviewable_type, presence: true, inclusion: { in: %w[Item Combo User] }
  validates :user_id, uniqueness: {
    scope: %i[reviewable_type reviewable_id order_id],
    message: :already_reviewed
  }
  validate :user_must_be_client
  validate :images_format_and_size
  validate :review_linked_to_ordered_item
  validate :review_linked_to_server

  scope :active, -> { where(deleted_at: nil) }

  def soft_delete!(reason: nil)
    update(deleted_at: Time.current, deletion_reason: reason)
  end

  def as_json(_options = {})
    {
      id: id,
      user_id: user_id,
      user_name: user ? "#{user.first_name} #{user.last_name}" : nil,
      reviewable_type: reviewable_type,
      reviewable_id: reviewable_id,
      reviewable_name: compute_reviewable_name,
      order_id: order_id,
      rating: rating,
      comment: comment,
      image_urls: if images.attached?
                    images.map do |img|
                      Rails.application.routes.url_helpers.rails_blob_url(img, only_path: true)
                    end
                  else
                    []
                  end,
      image_signed_ids: if images.attached?
                          images.map { |img| img.signed_id }
                        else
                          []
                        end,
      created_at: created_at,
      updated_at: updated_at,
      deleted_at: deleted_at,
      deletion_reason: deletion_reason
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

    errors.add(:user, :must_be_client) unless user.is_a?(Client)
  end

  def images_format_and_size
    return unless images.attached?

    images.each do |img|
      unless img.content_type.in?(%w[image/jpeg image/png])
        errors.add(:images, :invalid_format)
        break
      end
      if img.byte_size > 5.megabytes
        errors.add(:images, :file_too_large)
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
    errors.add(:reviewable, :not_ordered) unless has_ordered
  end

  def review_linked_to_server
    return unless user.present? && reviewable_type == "User"

    reviewed_user = User.unscoped.find_by(id: reviewable_id)
    unless reviewed_user.is_a?(Waiter) || reviewed_user.is_a?(Administrator)
      errors.add(:reviewable, :must_be_waiter)
      return
    end
    served_by = Order.where(client_id: user_id, server_id: reviewable_id).exists?
    errors.add(:reviewable, :not_your_server) unless served_by
  end
end
