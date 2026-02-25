class AddIndexEndedAtToOrders < ActiveRecord::Migration[8.1]
  def change
    add_index :orders, [:deleted_at, :ended_at], name: "idx_orders_deleted_ended"
  end
end
