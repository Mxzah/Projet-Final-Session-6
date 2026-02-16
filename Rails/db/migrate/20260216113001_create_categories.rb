class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, limit: 100, null: false
      t.integer :position, null: false, default: 0
      t.datetime :created_at, null: false
    end

    add_index :categories, :name, unique: true, name: "uniq_categories_name"
    add_index :categories, :position, unique: true, name: "uniq_categories_position"
  end
end
