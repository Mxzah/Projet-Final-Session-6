require "test_helper"

class OrderPayFailTest < ActionDispatch::IntegrationTest
  setup do
    @user  = users(:valid_user)
    @table = tables(:table_one)
    @item  = items(:item_one)  # disponible via item_one_active fixture

    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    OrderLine.joins(:order).where(orders: { client_id: @user.id }).delete_all
    Order.where(client_id: @user.id).delete_all

    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    @order_id = JSON.parse(response.body)["data"]["id"]
  end

  # Test 1: Non authentifié → erreur
  test "pay retourne erreur si non authentifié" do
    delete "/users/sign_out", as: :json

    post "/api/orders/#{@order_id}/pay", params: { tip: 5.0 }, as: :json

    assert_response :ok
    assert_not JSON.parse(response.body)["success"]
  end

  # Test 2: Tip négatif → validation fail (modèle)
  test "pay retourne erreur si tip est négatif" do
    post "/api/orders/#{@order_id}/pay", params: { tip: -5.0 }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 3: Tip trop élevé (> 999.99) → validation fail (modèle)
  test "pay retourne erreur si tip dépasse 999.99" do
    post "/api/orders/#{@order_id}/pay", params: { tip: 1000.0 }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 4: Ligne non servie → erreur métier (contrôleur)
  test "pay retourne erreur si des lignes ne sont pas servies" do
    # Créer une ligne (statut: waiting par défaut)
    post "/api/orders/#{@order_id}/order_lines",
      params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item.id } },
      as: :json

    post "/api/orders/#{@order_id}/pay", params: { tip: 0 }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 5: Commande d'un autre client → not found
  test "pay retourne erreur pour commande d un autre client" do
    other_order_id = orders(:unassigned_order).id

    post "/api/orders/#{other_order_id}/pay", params: { tip: 0 }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
