class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.integer :rating, null: false
      t.string :comment, limit: 500, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at
      t.references :user, null: false, foreign_key: true
      t.string :reviewable_type, limit: 50, null: false
      t.bigint :reviewable_id, null: false
      t.datetime :deleted_at
    end

    add_index :reviews, [:reviewable_type, :reviewable_id], name: "idx_reviews_type_id"
    add_index :reviews, :deleted_at, name: "idx_reviews_deleted_at"
  end
end
