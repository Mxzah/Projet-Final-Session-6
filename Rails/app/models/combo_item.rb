class ComboItem < ApplicationRecord
  belongs_to :combo
  belongs_to :item

  include Rails.application.routes.url_helpers

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }
  validates :combo_id, uniqueness: { scope: :item_id, message: :taken }

  default_scope { where(deleted_at: nil) }

  def combo_name
    combo&.name
  end

  def item_name
    item&.name
  end

  def item_image_url
    item&.image&.attached? ? url_for(item.image) : nil
  end

  def as_json(options = {})
    super(options.reverse_merge(
      only: [ :id, :combo_id, :item_id, :quantity, :deleted_at ],
      methods: [ :combo_name, :item_name, :item_image_url ]
    ))
  end

  def soft_delete!
    update(deleted_at: Time.current)
    self
  end
end
