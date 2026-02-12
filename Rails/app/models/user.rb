class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  before_validation :set_default_type, on: :create

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :type, presence: true
  validates :status, presence: true
  validates :password, length: { minimum: 6, maximum: 128 }, if: :password_required?

  # Soft delete scope
  default_scope { where(deleted_at: nil) }

  def soft_delete
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
