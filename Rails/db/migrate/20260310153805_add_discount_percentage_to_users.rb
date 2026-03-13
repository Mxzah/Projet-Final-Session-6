class AddDiscountPercentageToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :discount_percentage, :integer, default: 0, null: false
  end
end
