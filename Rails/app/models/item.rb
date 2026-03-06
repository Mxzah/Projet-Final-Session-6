# frozen_string_literal: true

# Individual menu item within a category
class Item < ApplicationRecord
  belongs_to :category
  has_many :combo_items
  has_many :combos, through: :combo_items
  has_many :order_lines, as: :orderable
  has_many :reviews, as: :reviewable
  has_many :availabilities, as: :available

  has_one_attached :image

  include Rails.application.routes.url_helpers

  def category_name
    category&.name
  end

  def image_url
    image.attached? ? rails_storage_proxy_path(image) : nil
  end

  def in_use
    order_lines.any? || combo_items.any?
  end

  def as_json(options = {})
    super(options).tap { |h| h["price"] = h["price"].to_f if h.key?("price") }
  end

  validates :name, presence: true, length: { maximum: 100 },
                   format: { without: /\A\s*\z/, message: :only_whitespace }
  validates :description, length: { maximum: 255 },
                          format: { without: /\A\s*\z/, message: :only_whitespace }, allow_blank: true
  validates :price, presence: true,
                    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 9999.99 }
  validate :image_presence
  validate :deleted_at_must_be_now
  validates :image, content_type: { in: %w[image/jpeg image/png], message: :invalid_format },
                    size: { less_than: 5.megabytes, message: :file_too_large }, if: :image_attached?

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
    errors.add(:image, :required) unless image.attached?
  end

  def image_attached?
    image.attached?
  end

  def deleted_at_must_be_now
    return if deleted_at.nil?
    return unless deleted_at_changed?

    return unless (deleted_at - Time.current).abs > 5.seconds

    errors.add(:deleted_at, :must_be_now)
  end
end
