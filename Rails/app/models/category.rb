class Category < ApplicationRecord
  has_many :items, dependent: :restrict_with_error
  has_many :availabilities, as: :available

  before_destroy :cleanup_availabilities

  private

  def cleanup_availabilities
    now = Time.current
    availabilities.where("start_at > ?", now).delete_all
    availabilities.where("start_at <= ? AND end_at > ?", now, now).update_all(end_at: now)
  end
end
