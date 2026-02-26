class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :orders_as_client, class_name: "Order", foreign_key: :client_id
  has_many :orders_as_server, class_name: "Order", foreign_key: :server_id
  has_many :reviews

  before_validation :set_default_type, on: :create

  validates :first_name, presence: true, length: { maximum: 50 },
                         format: { without: /\A\s*\z/, message: "ne peut pas être composé uniquement d'espaces" }
  validates :last_name, presence: true, length: { maximum: 50 },
                        format: { without: /\A\s*\z/, message: "ne peut pas être composé uniquement d'espaces" }
  validates :type, presence: true, inclusion: { in: %w[Administrator Waiter Client Cook] }
  validates :status, presence: true, inclusion: { in: %w[active inactive blocked] }
  validates :password, length: { minimum: 6, maximum: 128 }, if: :password_required?

  default_scope { where(deleted_at: nil) }

  def soft_delete!
    update(deleted_at: Time.current)
  end

  def active_for_authentication?
    super && status == 'active' && deleted_at.nil?
  end

  private

  def set_default_type
    self.type ||= 'Client'
  end

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
end
