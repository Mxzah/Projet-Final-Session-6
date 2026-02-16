class CreateCombos < ActiveRecord::Migration[8.1]
  def change
    create_table :combos do |t|
      t.string :name, limit: 100, null: false
      t.string :description, limit: 255
      t.decimal :price, precision: 6, scale: 2, null: false
      t.datetime :created_at, null: false
      t.datetime :deleted_at
    end

    add_index :combos, :deleted_at, name: "idx_combos_deleted_at"
  end
end
