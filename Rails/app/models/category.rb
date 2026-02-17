class Category < ApplicationRecord
  has_many :items, dependent: :restrict_with_error
  has_many :availabilities, as: :available

end
