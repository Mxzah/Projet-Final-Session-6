# frozen_string_literal: true

# Administrator: full access to all features, can also serve tables
class Administrator < User
  has_many :orders_as_server, class_name: "Order", foreign_key: :server_id

  def employee?
    true
  end

  def can_review?
    false
  end

  def active_orders
    orders_as_server.where(ended_at: nil)
  end
end
