# frozen_string_literal: true

# Combination meal with multiple items
class Combo < ApplicationRecord
  has_many :combo_items
  has_many :items, through: :combo_items
  has_many :order_lines, as: :orderable
  has_many :reviews, as: :reviewable
  has_many :availabilities, as: :available

  has_one_attached :image

  include Rails.application.routes.url_helpers

  def image_url
    image.attached? ? rails_storage_proxy_path(image) : nil
  end

  def as_json(options = {})
    super(options.reverse_merge(
      only: %i[id name description price created_at deleted_at],
      methods: [ :image_url ],
      include: { availabilities: { only: %i[id start_at end_at description] } }
    )).tap { |h| h["price"] = h["price"].to_f if h.key?("price") }
  end

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
    return unless name.is_a?(String) && !name.empty? && name.strip.empty?

    errors.add(:name, :blank)
  end

  def description_not_only_whitespace
    return unless description.is_a?(String) && !description.empty? && description.strip.empty?

    errors.add(:description, :invalid)
  end

  def image_content_type_validation
    return unless image.attached?

    return if image.content_type.in?(%w[image/jpeg image/png])

    errors.add(:image, :invalid_content_type)
  end

  def image_size_validation
    return unless image.attached?

    return unless image.blob.byte_size > 5.megabytes

    errors.add(:image, :file_size_too_large)
  end
end
