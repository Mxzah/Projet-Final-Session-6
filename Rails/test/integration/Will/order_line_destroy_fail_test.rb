require "test_helper"

class OrderLineDestroyFailTest < ActionDispatch::IntegrationTest
  setup do
    @user         = users(:valid_user)
    @closed_order = orders(:closed_order)
    @served_line  = order_lines(:line_item_one)  # status: served, order: closed_order

    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
  end

  # Test 1: Non authentifié → erreur
  test "destroy retourne erreur si non authentifié" do
    delete "/users/sign_out", as: :json

    delete "/api/orders/#{@closed_order.id}/order_lines/#{@served_line.id}", as: :json

    assert_response :ok
    assert_not JSON.parse(response.body)["success"]
  end

  # Test 2: Supprimer une ligne servie → refus du contrôleur (waiting || sent requis)
  test "destroy retourne erreur pour ligne avec statut served" do
    delete "/api/orders/#{@closed_order.id}/order_lines/#{@served_line.id}", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 3: Ligne d'une commande d'un autre client → not found
  test "destroy retourne erreur pour ligne d une commande d un autre client" do
    other_order_id = orders(:unassigned_order).id

    delete "/api/orders/#{other_order_id}/order_lines/999999", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
