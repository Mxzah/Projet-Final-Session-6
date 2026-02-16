class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.integer :nb_people, null: false
      t.string :note, limit: 255
      t.decimal :tip, precision: 5, scale: 2
      t.datetime :created_at, null: false
      t.datetime :ended_at
      t.references :table, null: false, foreign_key: true
      t.bigint :client_id, null: false
      t.bigint :server_id
      t.references :vibe, foreign_key: true
      t.datetime :deleted_at
    end

    add_foreign_key :orders, :users, column: :client_id  #reference de client_id de la table users
    add_foreign_key :orders, :users, column: :server_id  #reference de server_id de la table users
    add_index :orders, :client_id, name: "idx_orders_client_id"
    add_index :orders, :server_id, name: "idx_orders_server_id"
    add_index :orders, :created_at, name: "idx_orders_created_at"
    add_index :orders, :deleted_at, name: "idx_orders_deleted_at"
  end
end
