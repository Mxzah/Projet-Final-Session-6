# frozen_string_literal: true

# Time-based availability window for categories, items, tables, and combos
class Availability < ApplicationRecord
  belongs_to :available, polymorphic: true
  AVAILABLE_TYPES = %w[Category Item Table Combo].freeze
  MINIMUM_DURATION = 1.hour

  validates :start_at, presence: true
  validates :description, length: { maximum: 255 },
                          format: { without: /\A\s*\z/, message: :only_spaces }, allow_blank: true
  validates :available_type, presence: true, inclusion: { in: AVAILABLE_TYPES }
  validate :start_at_not_in_past
  validate :end_at_after_start_at
  validate :minimum_duration
  validate :no_overlapping_periods
  validate :available_not_deleted

  private

  def start_at_not_in_past
    return unless start_at.present?
    return if persisted? && start_at_was.present? && start_at.beginning_of_minute == start_at_was.beginning_of_minute

    errors.add(:start_at, :in_past) if start_at < Time.current.beginning_of_minute
  end

  def end_at_after_start_at
    return unless end_at.present? && start_at.present?

    errors.add(:end_at, :before_start) if end_at < start_at
  end

  def minimum_duration
    return unless end_at.present? && start_at.present?
    return if persisted? && start_at < Time.current

    return unless (end_at - start_at) < MINIMUM_DURATION

    errors.add(:end_at, :minimum_duration)
  end

  def available_not_deleted
    return unless available_id.present?

    return unless %w[Item Table Combo].include?(available_type)

    record = available_type.constantize

    return if record.exists?(id: available_id)

    errors.add(:base, :archived_record)
  end

  def no_overlapping_periods
    return unless start_at.present? && end_at.present? && available_id.present? && available_type.present?

    overlaps = Availability.where(available_id: available_id, available_type: available_type)
                           .where.not(id: id)
                           .where("start_at < ? AND end_at > ?", end_at, start_at)

    errors.add(:base, :overlapping) if overlaps.exists?
  end
end
