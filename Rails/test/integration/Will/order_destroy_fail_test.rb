require "test_helper"

class OrderDestroyFailTest < ActionDispatch::IntegrationTest
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
  test "destroy retourne erreur si non authentifié" do
    delete "/users/sign_out", as: :json

    delete "/api/orders/#{@order_id}", as: :json

    assert_response :ok
    assert_not JSON.parse(response.body)["success"]
  end

  # Test 2: Commande d'un autre client → not found
  test "destroy retourne erreur pour commande d un autre client" do
    other_order_id = orders(:unassigned_order).id

    delete "/api/orders/#{other_order_id}", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
