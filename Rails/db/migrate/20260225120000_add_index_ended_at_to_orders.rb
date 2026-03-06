# frozen_string_literal: true

# Add index on ended_at for orders
class AddIndexEndedAtToOrders < ActiveRecord::Migration[8.1]
  def change
    add_index :orders, %i[deleted_at ended_at], name: 'idx_orders_deleted_ended'
  end
end
