# frozen_string_literal: true

require "test_helper"

class ServerOrdersFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @waiter = users(:waiter_user)
    @client = users(:valid_user)
    @cook = users(:cook_user)

    # Connexion admin pour créer la table
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    post "/api/tables", params: { table: { number: 601, nb_seats: 4 } }, as: :json
    assert_response :ok
    @table_data = JSON.parse(response.body)["data"]
    @table = Table.find(@table_data["id"])

    # Fermer la commande ouverte du fixture pour valid_user
    Order.where(client: @client, ended_at: nil).update_all(ended_at: Time.current)

    delete "/users/sign_out", as: :json
  end

  # ══════════════════════════════════════════
  # AUTORISATION — GET /api/server/orders
  # ══════════════════════════════════════════

  # Test 1: Un client ne peut PAS accéder aux commandes serveur
  test "client ne peut pas accéder à GET /api/server/orders" do
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    get "/api/server/orders", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 2: Un cuisinier ne peut PAS accéder aux commandes serveur
  test "cuisinier ne peut pas accéder à GET /api/server/orders" do
    post "/users/sign_in", params: {
      user: { email: @cook.email, password: "password123" }
    }, as: :json

    get "/api/server/orders", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # ASSIGNATION SERVER_ID — POST /api/orders (ignoré)
  # ══════════════════════════════════════════

  # Test 3: Création de commande avec server_id invalide (Client) — ignore silencieusement
  test "create order avec server_id client ignore le server_id" do
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    post "/api/orders", params: {
      order: { table_id: @table.id, nb_people: 2, server_id: @client.id }
    }, as: :json

    json = JSON.parse(response.body)
    assert json["success"]
    assert_nil json["data"]["server_id"]
  end

  # Test 4: Création de commande avec server_id invalide (Cook) — ignore silencieusement
  test "create order avec server_id cook ignore le server_id" do
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    post "/api/orders", params: {
      order: { table_id: @table.id, nb_people: 2, server_id: @cook.id }
    }, as: :json

    json = JSON.parse(response.body)
    assert json["success"]
    assert_nil json["data"]["server_id"]
  end

  # Test 5: Création de commande avec server_id inexistant — ignore silencieusement
  test "create order avec server_id inexistant ignore le server_id" do
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    post "/api/orders", params: {
      order: { table_id: @table.id, nb_people: 2, server_id: 999_999 }
    }, as: :json

    json = JSON.parse(response.body)
    assert json["success"]
    assert_nil json["data"]["server_id"]
  end
end
