require "test_helper"

class ServerTablesFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @waiter = users(:waiter_user)
    @client = users(:valid_user)
    @cook = users(:cook_user)

    # Connexion admin pour créer les tables
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    post "/api/tables", params: { table: { number: 501, nb_seats: 4 } }, as: :json
    assert_response :created

    delete "/users/sign_out", as: :json
  end

  # ══════════════════════════════════════════
  # AUTORISATION — GET /api/server/tables
  # ══════════════════════════════════════════

  # Test 1: Un client ne peut PAS accéder à la liste des tables serveur
  test "client ne peut pas accéder à GET /api/server/tables" do
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    get "/api/server/tables", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 2: Un cuisinier ne peut PAS accéder à la liste des tables serveur
  test "cuisinier ne peut pas accéder à GET /api/server/tables" do
    post "/users/sign_in", params: {
      user: { email: @cook.email, password: "password123" }
    }, as: :json

    get "/api/server/tables", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 3: Un utilisateur non connecté ne peut PAS accéder
  test "utilisateur non connecté ne peut pas accéder à GET /api/server/tables" do
    get "/api/server/tables", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
