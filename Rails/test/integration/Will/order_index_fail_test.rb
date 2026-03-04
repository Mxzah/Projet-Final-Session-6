require "test_helper"

class OrderIndexFailTest < ActionDispatch::IntegrationTest
  # Test 1: Non authentifié → success false
  test "index retourne erreur si non authentifié" do
    get "/api/orders", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 2: Les commandes d'un autre client ne sont pas visibles
  test "index ne retourne pas les commandes des autres utilisateurs" do
    # Login valid_user
    post "/users/sign_in", params: { user: { email: users(:valid_user).email, password: "password123" } }, as: :json
    OrderLine.joins(:order).where(orders: { client_id: users(:valid_user).id }).delete_all
    Order.where(client_id: users(:valid_user).id).delete_all

    # La commande unassigned_order appartient à inactive_user
    other_order_id = orders(:unassigned_order).id

    get "/api/orders", as: :json

    json = JSON.parse(response.body)
    ids = json["data"].map { |o| o["id"] }
    assert_not_includes ids, other_order_id
  end
end
