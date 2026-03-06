# frozen_string_literal: true

# Add server_released flag to orders
class AddServerReleasedToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :server_released, :boolean, default: false, null: false
  end
end
