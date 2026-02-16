class CreateVibes < ActiveRecord::Migration[8.1]
  def change
    create_table :vibes do |t|
      t.string :name, limit: 50, null: false
      t.string :color, limit: 7, null: false
      t.datetime :created_at, null: false
      t.datetime :deleted_at
    end

    add_index :vibes, :name, unique: true, name: "uniq_vibes_name"
    add_index :vibes, :deleted_at, name: "idx_vibes_deleted_at"
  end
end
