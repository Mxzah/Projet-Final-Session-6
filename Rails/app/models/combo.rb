class Combo < ApplicationRecord
  has_many :combo_items
  has_many :items, through: :combo_items
  has_many :order_lines, as: :orderable
  has_many :reviews, as: :reviewable
  
  has_one_attached :image


end
