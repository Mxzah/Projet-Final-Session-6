class CreateAvailabilities < ActiveRecord::Migration[8.1]
  def change
    create_table :availabilities do |t|
      t.datetime :start_at, null: false
      t.datetime :end_at
      t.string :description, limit: 255
      t.string :available_type, limit: 50, null: false
      t.bigint :available_id, null: false
      t.datetime :created_at, null: false
    end

    add_index :availabilities, [:available_type, :available_id], name: "idx_availabilities_type_id"
  end
end
