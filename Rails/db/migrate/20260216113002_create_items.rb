class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :name, limit: 100, null: false
      t.string :description, limit: 255
      t.decimal :price, precision: 6, scale: 2, null: false
      t.references :category, null: false, foreign_key: true
      t.datetime :created_at, null: false
      t.datetime :deleted_at
    end

    add_index :items, :deleted_at, name: "idx_items_deleted_at"
  end
end
