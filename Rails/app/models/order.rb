# frozen_string_literal: true

# Customer order associated with a table
class Order < ApplicationRecord
  belongs_to :table
  belongs_to :client, class_name: "User"
  belongs_to :server, class_name: "User", optional: true
  belongs_to :vibe, optional: true
  has_many :order_lines, dependent: :destroy

  # Scope: voir si ouverte ou fermée (ended_at IS NULL ou NOT NULL)
  scope :open, -> { where(ended_at: nil) }

  before_save :snapshot_discount, if: :closing?

  validates :nb_people, presence: true,
                        numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 20 }
  validates :note, length: { maximum: 255 },
                   format: { without: /\A\s*\z/, message: :only_spaces }, allow_blank: true
  validates :tip, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999.99 }, allow_nil: true
  validate :ended_at_after_created_at
  validate :client_has_no_other_open_order
  validate :nb_people_within_table_capacity

  default_scope { where(deleted_at: nil) }

  # JSON serialization for API responses
  def as_json(_options = {})
    lines_data = order_lines.map(&:as_json)
    total = lines_data.sum { |l| l[:unit_price] * l[:quantity] }

    # Closed orders use the snapshot; open orders compute live from tenure
    discount_pct = ended_at? ? (read_attribute(:discount_percentage) || 0) : (client&.discount_percentage || 0)
    discount_amt = (total * discount_pct / 100.0).round(2)
    adj_total = (total - discount_amt).round(2)

    {
      id: id,
      nb_people: nb_people,
      note: note,
      tip: tip.to_f,
      table_id: table_id,
      table_number: table&.number,
      client_id: client_id,
      server_id: server_id,
      server_name: server ? "#{server.first_name} #{server.last_name}" : nil,
      vibe_id: vibe_id,
      vibe_name: vibe&.name,
      vibe_color: vibe&.color,
      created_at: created_at,
      ended_at: ended_at,
      server_released: server_released,
      order_lines: lines_data,
      total: total,
      discount_percentage: discount_pct,
      discount_amount: discount_amt,
      adjusted_total: adj_total
    }
  end

  private

  # Snapshot the employee discount when the order is being closed
  def closing?
    ended_at.present? && ended_at_changed?
  end

  def snapshot_discount
    self.discount_percentage = client&.discount_percentage || 0
  end

  # ended_at must be >= created_at
  def ended_at_after_created_at
    return unless ended_at.present? && created_at.present?

    errors.add(:ended_at, :before_created) if ended_at < created_at
  end

  # A client can only have one open order at a time (ended_at IS NULL)
  def client_has_no_other_open_order
    return unless client_id.present?

    existing = Order.unscoped.where(client_id: client_id, ended_at: nil, deleted_at: nil).where.not(id: id)
    errors.add(:client_id, :has_open_order) if existing.exists?
  end

  # nb_people cannot exceed the table's nb_seats
  def nb_people_within_table_capacity
    return unless table.present? && nb_people.present?
    return if nb_people <= table.nb_seats

    errors.add(:nb_people, :exceeds_capacity, max: table.nb_seats)
  end
end
