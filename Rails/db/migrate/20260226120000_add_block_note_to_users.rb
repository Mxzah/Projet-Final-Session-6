# frozen_string_literal: true

# Add block_note field to users
class AddBlockNoteToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :block_note, :string
  end
end
