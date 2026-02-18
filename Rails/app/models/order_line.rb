class OrderLine < ApplicationRecord
  STATUSES = %w[sent in_preparation ready served].freeze
  STATUS_ORDER = STATUSES.each_with_index.to_h.freeze

  belongs_to :order
  belongs_to :orderable, polymorphic: true

  validates :quantity, presence: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 50 }
  validates :unit_price, presence: true,
                         numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 9999.99 }
  validates :note, length: { maximum: 255 },
                   format: { without: /\A\s*\z/, message: "ne peut pas être composé uniquement d'espaces" }, allow_blank: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :orderable_type, presence: true, inclusion: { in: %w[Item Combo] }
  validate :status_must_follow_sequence, if: :status_changed?
  validate :orderable_must_be_available
  validate :cannot_modify_unless_sent, on: :update

  private

  
end
