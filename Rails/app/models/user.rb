class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  VALID_TYPES = %w[Administrator Waiter Client Cook].freeze
  VALID_STATUSES = %w[active inactive blocked].freeze
  SORTABLE_COLUMNS = %w[first_name last_name email created_at].freeze
  EMPLOYEE_TYPES = %w[Administrator Waiter Cook].freeze

  has_many :orders_as_client, class_name: "Order", foreign_key: :client_id
  has_many :orders_as_server, class_name: "Order", foreign_key: :server_id
  has_many :reviews

  enum :status, { active: "active", inactive: "inactive", blocked: "blocked" }, default: :active

  attribute :type, :string, default: "Client"

  before_validation :strip_blank_password

  validates :first_name, presence: true, length: { maximum: 50 },
                         format: { without: /\A\s*\z/, message: "can't be only whitespace" }
  validates :last_name, presence: true, length: { maximum: 50 },
                        format: { without: /\A\s*\z/, message: "can't be only whitespace" }
  validates :type, presence: true, inclusion: { in: VALID_TYPES }
  validates :password, length: { minimum: 6, maximum: 128 }, if: :password_required?

  # Soft-delete: default_scope excludes records where deleted_at is set.
  # Use User.unscoped to query soft-deleted records.
  default_scope { where(deleted_at: nil) }

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def active_for_authentication?
    super && active? && deleted_at.nil?
  end

  def employee_discount_percentage
    return 0 unless EMPLOYEE_TYPES.include?(type)
    tenure_months = ((Time.current - created_at) / 1.month.seconds).floor
    if tenure_months >= 24
      15
    elsif tenure_months >= 12
      10
    elsif tenure_months >= 6
      5
    else
      0
    end
  end

  def as_json(options = {})
    {
      id: id,
      email: email,
      first_name: first_name,
      last_name: last_name,
      type: type,
      status: status,
      block_note: block_note,
      created_at: created_at
    }
  end

  private

  def strip_blank_password
    if password.blank?
      self.password = nil
      self.password_confirmation = nil
    end
  end

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
end
