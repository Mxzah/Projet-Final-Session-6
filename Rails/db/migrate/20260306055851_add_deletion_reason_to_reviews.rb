# frozen_string_literal: true

# Add deletion_reason column for review moderation
class AddDeletionReasonToReviews < ActiveRecord::Migration[8.1]
  def change
    add_column :reviews, :deletion_reason, :string, limit: 500
  end
end
