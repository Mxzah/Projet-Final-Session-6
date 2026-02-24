class Order < ApplicationRecord
  belongs_to :table
  belongs_to :client, class_name: "User"   #belongs_to est OBLIGATOIRE (
  belongs_to :server, class_name: "User", optional: true
  belongs_to :vibe, optional: true
  has_many :order_lines

  validates :nb_people, presence: true,
                        numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 20 }
  validates :note, length: { maximum: 255 },
                   format: { without: /\A\s*\z/, message: "ne peut pas être composé uniquement d'espaces" }, allow_blank: true
  validates :tip, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999.99 }, allow_nil: true
  validate :ended_at_after_created_at
  validate :client_has_no_other_open_order
  validate :nb_people_within_table_capacity

  default_scope { where(deleted_at: nil) }

  def soft_delete
    update(deleted_at: Time.current)
  end

  private

  def ended_at_after_created_at   #CHECK (ended_at >= created_at)
    return unless ended_at.present? && created_at.present?
    errors.add(:ended_at, "doit être après la date de création") if ended_at < created_at
  end

 



  def client_has_no_other_open_order  #un client ne peut avoir qu'une seule commande ouverte (ended_at IS NULL)
    return unless client_id.present?
    existing = Order.unscoped.where(client_id: client_id, ended_at: nil, deleted_at: nil).where.not(id: id)
    errors.add(:client_id, "a déjà une commande ouverte") if existing.exists?
  end

  def nb_people_within_table_capacity
    return unless table.present? && nb_people.present?
    return if nb_people <= table.nb_seats
    errors.add(:nb_people, "cannot exceed the table capacity (#{table.nb_seats} people max)")
  end
end
