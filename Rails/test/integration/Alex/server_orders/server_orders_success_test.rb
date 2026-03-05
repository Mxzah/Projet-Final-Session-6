require "test_helper"

class ServerOrdersSuccessTest < ActionDispatch::IntegrationTest
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
    assert_response :created
    @table_data = JSON.parse(response.body)["data"]
    @table = Table.find(@table_data["id"])

    # Fermer la commande ouverte du fixture pour valid_user
    Order.where(client: @client, ended_at: nil).update_all(ended_at: Time.current)

    delete "/users/sign_out", as: :json
  end

  # ══════════════════════════════════════════
  # AUTORISATION — GET /api/server/orders
  # ══════════════════════════════════════════

  # Test 1: Un serveur peut accéder à ses commandes
  test "serveur peut accéder à GET /api/server/orders" do
    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    get "/api/server/orders", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not_nil json["data"]["mine"]
  end

  # Test 2: Un admin peut accéder aux commandes serveur
  test "admin peut accéder à GET /api/server/orders" do
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    get "/api/server/orders", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end

  # ══════════════════════════════════════════
  # CONTENU — Commandes du serveur
  # ══════════════════════════════════════════

  # Test 3: Le serveur voit uniquement ses commandes (mine)
  test "serveur voit ses propres commandes dans mine" do
    order = Order.new(
      table: @table, client: @client, server: @waiter, nb_people: 2
    )
    order.save(validate: false)

    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    get "/api/server/orders", as: :json

    json = JSON.parse(response.body)
    assert json["success"]
    mine = json["data"]["mine"]
    assert mine.length >= 1
    assert mine.all? { |o| o["server_id"] == @waiter.id }
  end

  # Test 4: Chaque commande contient les champs attendus
  test "commande contient table_number, nb_people, server_name, order_lines" do
    order = Order.new(
      table: @table, client: @client, server: @waiter, nb_people: 3, note: "Test note"
    )
    order.save(validate: false)

    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    get "/api/server/orders", as: :json

    json = JSON.parse(response.body)
    order = json["data"]["mine"].first
    assert_not_nil order["id"]
    assert_not_nil order["table_number"]
    assert_not_nil order["nb_people"]
    assert_not_nil order["server_name"]
    assert_not_nil order["order_lines"]
    assert_not_nil order["created_at"]
  end

  # ══════════════════════════════════════════
  # ASSIGNATION SERVER_ID — POST /api/orders
  # ══════════════════════════════════════════

  # Test 5: Création de commande avec server_id valide (Waiter)
  test "create order avec server_id waiter assigne le serveur" do
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    post "/api/orders", params: {
      order: { table_id: @table.id, nb_people: 2, server_id: @waiter.id }
    }, as: :json

    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal @waiter.id, json["data"]["server_id"]

    # Validation BD
    order = Order.find(json["data"]["id"])
    assert_equal @waiter.id, order.server_id
  end

  # Test 6: Création de commande sans server_id — pas de serveur assigné
  test "create order sans server_id laisse server_id nil" do
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    post "/api/orders", params: {
      order: { table_id: @table.id, nb_people: 2 }
    }, as: :json

    json = JSON.parse(response.body)
    assert json["success"]
    assert_nil json["data"]["server_id"]
  end
end
