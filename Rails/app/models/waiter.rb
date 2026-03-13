# frozen_string_literal: true

# Waiter/Server: serves tables and manages orders
class Waiter < User
  has_many :orders_as_server, class_name: "Order", foreign_key: :server_id

  scope :available, -> { where(status: :active) }

  def employee?
    true
  end

  def can_review?
    false
  end

  def active_orders
    orders_as_server.where(ended_at: nil)
  end

  def served_orders
    orders_as_server.where.not(ended_at: nil)
  end
end
