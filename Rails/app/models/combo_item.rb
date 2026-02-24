class ComboItem < ApplicationRecord
  belongs_to :combo
  belongs_to :item

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :combo_id, uniqueness: { scope: :item_id }
end
