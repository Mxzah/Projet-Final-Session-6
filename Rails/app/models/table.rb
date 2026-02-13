class Table < ApplicationRecord
  validates :number, presence: true, uniqueness: true, numericality: { only_integer: true, greater_than: 0 }
  validates :qr_token, presence: true, uniqueness: true
  validates :capacity, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 20 }
  validates :status, presence: true, inclusion: { in: %w[available occupied reserved maintenance] }

  before_validation :generate_qr_token, on: :create

  scope :available, -> { where(status: 'available') }

  def occupy!
    update!(status: 'occupied')
  end

  def release!
    update!(status: 'available')
  end

  private

  def generate_qr_token
    self.qr_token ||= SecureRandom.uuid
  end
end
