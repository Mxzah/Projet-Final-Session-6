class Availability < ApplicationRecord
  belongs_to :available, polymorphic: true
end
