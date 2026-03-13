# frozen_string_literal: true

# Base user model with STI for role-based authentication
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

  # Employee discount based on tenure (time since account creation):
  #   < 6 months  → 0%
  #   6–12 months → 5%
  #   1–2 years   → 10%
  #   2+ years    → 15%
  # Non-employees (Clients) always get 0%.
  def discount_percentage
    return 0 unless employee?

    months = ((Time.current - created_at) / 1.month).floor
    if months >= 24
      15
    elsif months >= 12
      10
    elsif months >= 6
      5
    else
      0
    end
  end

  def employee?
    EMPLOYEE_TYPES.include?(type)
  end

  def can_review?
    false
  end

  def as_json(_options = {})
    {
      id: id,
      email: email,
      first_name: first_name,
      last_name: last_name,
      type: type,
      status: status,
      block_note: block_note,
      discount_percentage: discount_percentage,
      created_at: created_at
    }
  end

  private

  def strip_blank_password
    return unless password.blank?

    self.password = nil
    self.password_confirmation = nil
  end

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
end
