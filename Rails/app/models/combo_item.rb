class ComboItem < ApplicationRecord
  belongs_to :combo
  belongs_to :item

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }
  validates :combo_id, uniqueness: { scope: :item_id, message: :taken }

  default_scope { where(deleted_at: nil) }

  def soft_delete!
    update(deleted_at: Time.current)
    self
  end
end
