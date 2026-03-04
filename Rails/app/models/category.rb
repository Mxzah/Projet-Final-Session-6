class Category < ApplicationRecord
  has_many :items, dependent: :restrict_with_error
  has_many :availabilities, as: :available

  before_destroy :cleanup_availabilities
  validates :name, presence: true, uniqueness: true, length: { maximum: 100 },
                   format: { without: /\A\s*\z/, message: "ne peut pas être composé uniquement d'espaces" }
  validates :position, presence: true, uniqueness: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def as_json(options = {})
    super(options.reverse_merge(
      only: [ :id, :name, :position, :created_at ],
      include: { availabilities: { only: [ :id, :start_at, :end_at, :description ] } }
    ))
  end

  private

  def cleanup_availabilities
    now = Time.current
    availabilities.where("start_at > ?", now).delete_all
    availabilities.where("start_at <= ? AND end_at > ?", now, now).update_all(end_at: now)
  end
end
