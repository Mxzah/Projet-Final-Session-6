# frozen_string_literal: true

# Cook: kitchen staff who prepares orders
class Cook < User
  scope :available, -> { where(status: :active) }

  def employee?
    true
  end

  def can_review?
    false
  end
end
