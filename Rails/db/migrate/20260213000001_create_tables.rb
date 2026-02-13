class CreateTables < ActiveRecord::Migration[8.1]
  def change
    create_table :tables do |t|
      t.integer :number, null: false
      t.string :qr_token, null: false, limit: 36
      t.integer :capacity, null: false, default: 4
      t.string :status, null: false, limit: 20, default: 'available'

      t.timestamps
    end

    add_index :tables, :number, unique: true
    add_index :tables, :qr_token, unique: true
    add_index :tables, :status
  end
end
