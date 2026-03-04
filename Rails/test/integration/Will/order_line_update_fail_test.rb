require "test_helper"

class OrderLineUpdateFailTest < ActionDispatch::IntegrationTest
  setup do
    @user         = users(:valid_user)
    @closed_order = orders(:closed_order)
    @served_line  = order_lines(:line_item_one)  # status: served, order: closed_order

    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
  end

  # Test 1: Non authentifié → erreur
  test "update retourne erreur si non authentifié" do
    delete "/users/sign_out", as: :json

    put "/api/orders/#{@closed_order.id}/order_lines/#{@served_line.id}",
      params: { order_line: { quantity: 2 } },
      as: :json

    assert_response :ok
    assert_not JSON.parse(response.body)["success"]
  end

  # Test 2: Modifier une ligne servie → validation fail (cannot_modify_unless_sent)
  test "update retourne erreur si la ligne est servie" do
    put "/api/orders/#{@closed_order.id}/order_lines/#{@served_line.id}",
      params: { order_line: { quantity: 5 } },
      as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 3: Quantité invalide (0) → validation fail
  test "update retourne erreur si quantity est 0" do
    @table = tables(:table_one)
    OrderLine.joins(:order).where(orders: { client_id: @user.id }).delete_all
    Order.where(client_id: @user.id).delete_all
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    order_id = JSON.parse(response.body)["data"]["id"]

    post "/api/orders/#{order_id}/order_lines",
      params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: items(:item_one).id } },
      as: :json
    line_id = JSON.parse(response.body)["data"]["id"]

    put "/api/orders/#{order_id}/order_lines/#{line_id}",
      params: { order_line: { quantity: 0 } },
      as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end
end
