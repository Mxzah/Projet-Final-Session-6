class CreateOrderLines < ActiveRecord::Migration[8.1]
  def change
    create_table :order_lines do |t|
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 6, scale: 2, null: false
      t.string :note, limit: 255
      t.string :status, limit: 20, null: false, default: "sent"
      t.references :order, null: false, foreign_key: true
      t.string :orderable_type, limit: 50, null: false
      t.bigint :orderable_id, null: false
      t.datetime :created_at, null: false
    end

    add_index :order_lines, [:orderable_type, :orderable_id], name: "idx_order_lines_type_id"
    add_index :order_lines, :status, name: "idx_order_lines_status"
  end
end
