class AddIndexesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :type, name: "idx_users_type"
    add_index :users, :status, name: "idx_users_status"
  end
end
