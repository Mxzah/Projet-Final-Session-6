require "test_helper"

class OrderUpdateFailTest < ActionDispatch::IntegrationTest
  setup do
    @user  = users(:valid_user)
    @table = tables(:table_one)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    OrderLine.joins(:order).where(orders: { client_id: @user.id }).delete_all
    Order.where(client_id: @user.id).delete_all

    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    @order_id = JSON.parse(response.body)["data"]["id"]
  end

  # Test 1: Non authentifié → erreur
  test "update retourne erreur si non authentifié" do
    delete "/users/sign_out", as: :json

    put "/api/orders/#{@order_id}", params: { order: { note: "Test" } }, as: :json

    assert_response :ok
    assert_not JSON.parse(response.body)["success"]
  end

  # Test 2: Commande d'un autre client → not found
  test "update retourne erreur pour commande d un autre client" do
    other_order_id = orders(:unassigned_order).id

    put "/api/orders/#{other_order_id}", params: { order: { note: "Hacked" } }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 3: Note trop longue → validation fail
  test "update retourne erreur si la note dépasse 255 caractères" do
    long_note = "a" * 256

    put "/api/orders/#{@order_id}", params: { order: { note: long_note } }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end
end
