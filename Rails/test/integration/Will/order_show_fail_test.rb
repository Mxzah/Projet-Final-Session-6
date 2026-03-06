# frozen_string_literal: true

require "test_helper"

class OrderShowFailTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    OrderLine.joins(:order).where(orders: { client_id: @user.id }).delete_all
    Order.where(client_id: @user.id).delete_all
  end

  # Test 1: Non authentifié → erreur
  test "show retourne erreur si non authentifié" do
    delete "/users/sign_out", as: :json

    get "/api/orders/999999", as: :json

    assert_response :ok
    assert_not JSON.parse(response.body)["success"]
  end

  # Test 2: Commande d'un autre utilisateur → not found
  test "show retourne erreur pour commande d un autre client" do
    other_order_id = orders(:unassigned_order).id

    get "/api/orders/#{other_order_id}", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 3: ID inexistant → not found
  test "show retourne erreur pour un id inexistant" do
    get "/api/orders/999999999", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end
end
