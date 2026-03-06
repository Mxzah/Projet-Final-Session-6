# frozen_string_literal: true

require "test_helper"

class OrderLineCreateFailTest < ActionDispatch::IntegrationTest
  setup do
    @user  = users(:valid_user)
    @table = tables(:table_one)
    @item  = items(:item_one) # disponible via item_one_active fixture
    @item_unavailable = items(:item_two) # PAS de disponibilité active

    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    OrderLine.joins(:order).where(orders: { client_id: @user.id }).delete_all
    Order.where(client_id: @user.id).delete_all

    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    @order_id = JSON.parse(response.body)["data"]["id"]
  end

  # Test 1: Non authentifié → erreur
  test "create retourne erreur si non authentifié" do
    delete "/users/sign_out", as: :json

    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item.id } },
         as: :json

    assert_response :ok
    assert_not JSON.parse(response.body)["success"]
  end

  # Test 2: Commande d'un autre utilisateur → not found
  test "create retourne erreur pour commande d un autre client" do
    other_order_id = orders(:unassigned_order).id

    post "/api/orders/#{other_order_id}/order_lines",
         params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item.id } },
         as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 3: Quantité manquante → validation fail
  test "create retourne erreur si quantity est absente" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { orderable_type: "Item", orderable_id: @item.id } },
         as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 4: Quantité invalide (0) → validation fail
  test "create retourne erreur si quantity est 0" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 0, orderable_type: "Item", orderable_id: @item.id } },
         as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 5: Item non disponible → validation fail (orderable_must_be_available)
  test "create retourne erreur si l item n est pas disponible" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item_unavailable.id } },
         as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end
end
