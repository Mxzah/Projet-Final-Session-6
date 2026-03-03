class ChangeOrderLineStatusDefaultToWaiting < ActiveRecord::Migration[8.1]
  def change
    change_column_default :order_lines, :status, from: "sent", to: "waiting"
  end
end
