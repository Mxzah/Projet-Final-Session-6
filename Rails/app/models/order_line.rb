class OrderLine < ApplicationRecord
  # Enum for status — provides scopes (.sent, .served) and query methods (.sent?, .served?)
  enum :status, { sent: "sent", in_preparation: "in_preparation", ready: "ready", served: "served" }, default: :sent, validate: true

  # Constants for sequential status logic
  STATUSES = %w[sent in_preparation ready served].freeze
  STATUS_ORDER = STATUSES.each_with_index.to_h.freeze

  belongs_to :order
  belongs_to :orderable, polymorphic: true

  # Scope: order lines belonging to open (not ended) orders
  scope :open, -> { joins(:order).where(orders: { ended_at: nil, deleted_at: nil }) }
  
  validates :quantity, presence: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 50 }
  validates :unit_price, presence: true,
                         numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 9999.99 }
  validates :note, length: { maximum: 255 },
                   format: { without: /\A\s*\z/, message: "cannot consist only of spaces" }, allow_blank: true
  # status validation is handled by enum (validate: true)
  validates :orderable_type, presence: true, inclusion: { in: %w[Item Combo] }

  validate :status_must_follow_sequence, if: :status_changed?
  validate :orderable_must_be_available
  validate :cannot_modify_unless_sent, on: :update

  # JSON serialization for API responses
  def as_json(options = {})
    {
      id: id,
      quantity: quantity,
      unit_price: unit_price.to_f,
      note: note,
      status: status,
      orderable_type: orderable_type,
      orderable_id: orderable_id,
      orderable_name: orderable&.name,
      orderable_description: orderable&.try(:description),
      created_at: created_at
    }
  end

  private

  def status_must_follow_sequence
    # Status must follow the sequential order: sent → in_preparation → ready → served
    return unless persisted? && status_was.present?

    old_index = STATUS_ORDER[status_was]
    new_index = STATUS_ORDER[status]

    return unless old_index && new_index

    if new_index != old_index + 1
      errors.add(:status, "must follow sequential order (sent → in_preparation → ready → served)")
    end
  end

  def orderable_must_be_available
    # The referenced item or combo must be available according to the Availability table
    return unless orderable_type.present? && orderable_id.present?

    available = Availability.where(available_type: orderable_type, available_id: orderable_id)
                            .where("start_at <= ? AND (end_at IS NULL OR end_at >= ?)", Time.current, Time.current)

    errors.add(:orderable, "is not currently available") unless available.exists?
  end

  def cannot_modify_unless_sent
    # A line can only have quantity/note changed if its status is 'sent'
    return unless status_was != "sent" && (quantity_changed? || note_changed? || orderable_id_changed?)

    errors.add(:base, "can only be modified when status is 'sent'")
  end
end
