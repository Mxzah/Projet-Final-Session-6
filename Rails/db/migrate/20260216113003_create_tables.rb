class CreateTables < ActiveRecord::Migration[8.1]
  def change
    create_table :tables do |t|
      t.integer :number, null: false
      t.integer :nb_seats, null: false
      t.string :temporary_code, limit: 50
      t.datetime :cleaned_at
      t.datetime :created_at, null: false
      t.datetime :deleted_at
    end

    add_index :tables, :number, unique: true, name: "uniq_tables_number"
    add_index :tables, :temporary_code, unique: true, name: "uniq_tables_temporary_code"
    add_index :tables, :deleted_at, name: "idx_tables_deleted_at"
  end
end
