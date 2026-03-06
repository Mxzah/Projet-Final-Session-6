class AddOrderIdToReviews < ActiveRecord::Migration[8.1]
  def change
    add_reference :reviews, :order, null: true, foreign_key: true
  end
end
