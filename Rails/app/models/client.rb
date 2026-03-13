# frozen_string_literal: true

# Client: restaurant customer who can place orders and leave reviews
class Client < User
  has_many :orders, foreign_key: :client_id
  has_many :reviews

  def employee?
    false
  end

  def can_review?
    true
  end
end
