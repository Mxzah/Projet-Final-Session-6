class AddQrRotatedAtToTables < ActiveRecord::Migration[8.1]
  def change
    add_column :tables, :qr_rotated_at, :datetime
    add_index :tables, :qr_rotated_at, name: "idx_tables_qr_rotated_at"
  end
end
