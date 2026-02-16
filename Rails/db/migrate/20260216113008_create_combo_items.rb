class CreateComboItems < ActiveRecord::Migration[8.1]
  def change
    create_table :combo_items do |t|
      t.references :combo, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.datetime :deleted_at
    end

    add_index :combo_items, [:combo_id, :item_id], unique: true, name: "uniq_combo_items"
    add_index :combo_items, :deleted_at, name: "idx_combo_items_deleted_at"
  end
end
