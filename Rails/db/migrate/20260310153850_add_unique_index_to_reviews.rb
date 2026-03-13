class AddUniqueIndexToReviews < ActiveRecord::Migration[8.1]
  def up
    # Remove duplicate reviews, keeping the oldest one per (user, reviewable, order)
    execute <<-SQL
      DELETE r1 FROM reviews r1
      INNER JOIN reviews r2
      ON r1.user_id = r2.user_id
        AND r1.reviewable_type = r2.reviewable_type
        AND r1.reviewable_id = r2.reviewable_id
        AND ((r1.order_id IS NULL AND r2.order_id IS NULL) OR r1.order_id = r2.order_id)
        AND r1.id > r2.id
    SQL

    add_index :reviews, %i[user_id reviewable_type reviewable_id order_id],
              unique: true,
              name: "uniq_review_per_user_reviewable_order"
  end

  def down
    remove_index :reviews, name: "uniq_review_per_user_reviewable_order"
  end
end
