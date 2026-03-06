# frozen_string_literal: true

require "test_helper"

class ServerTablesSuccessTest < ActionDispatch::IntegrationTest
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
    assert_response :ok
    @table1 = JSON.parse(response.body)["data"]

    post "/api/tables", params: { table: { number: 502, nb_seats: 6 } }, as: :json
    assert_response :ok
    @table2 = JSON.parse(response.body)["data"]

    post "/api/tables", params: { table: { number: 503, nb_seats: 2 } }, as: :json
    assert_response :ok
    @table3 = JSON.parse(response.body)["data"]

    delete "/users/sign_out", as: :json
  end

  # ══════════════════════════════════════════
  # AUTORISATION — GET /api/server/tables
  # ══════════════════════════════════════════

  # Test 1: Un serveur peut accéder à la liste des tables
  test "serveur peut accéder à GET /api/server/tables" do
    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    get "/api/server/tables", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_kind_of Array, json["data"]
  end

  # Test 2: Un admin peut accéder à la liste des tables
  test "admin peut accéder à GET /api/server/tables" do
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    get "/api/server/tables", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end

  # ══════════════════════════════════════════
  # CONTENU — Liste des tables
  # ══════════════════════════════════════════

  # Test 3: La réponse contient les champs attendus
  test "réponse contient id, number, capacity, status, qr_token" do
    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    get "/api/server/tables", as: :json

    json = JSON.parse(response.body)
    assert json["success"]

    table = json["data"].find { |t| t["number"] == 501 }
    assert_not_nil table
    assert_not_nil table["id"]
    assert_equal 501, table["number"]
    assert_equal 4, table["capacity"]
    assert_not_nil table["qr_token"]
    assert_includes %w[available occupied], table["status"]
  end

  # Test 4: Les tables sont triées par numéro
  test "tables triées par numéro croissant" do
    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    get "/api/server/tables", as: :json

    json = JSON.parse(response.body)
    numbers = json["data"].map { |t| t["number"] }
    assert_equal numbers, numbers.sort
  end

  # Test 5: Table sans commande ouverte est « available »
  test "table sans commande ouverte a status available" do
    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    get "/api/server/tables", as: :json

    json = JSON.parse(response.body)
    table = json["data"].find { |t| t["number"] == 501 }
    assert_equal "available", table["status"]
  end

  # Test 6: Table avec commande ouverte est « occupied »
  test "table avec commande ouverte a status occupied" do
    # Créer une commande ouverte sur la table (bypass validation)
    table_obj = Table.find(@table1["id"])
    order = Order.new(
      table: table_obj,
      client: @client,
      server: @waiter,
      nb_people: 2
    )
    order.save(validate: false)

    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    get "/api/server/tables", as: :json

    json = JSON.parse(response.body)
    table = json["data"].find { |t| t["number"] == 501 }
    assert_equal "occupied", table["status"]
  end

  # Test 7: Table occupée affiche le nom du serveur
  test "table occupée affiche server_name" do
    table_obj = Table.find(@table1["id"])
    order = Order.new(
      table: table_obj,
      client: @client,
      server: @waiter,
      nb_people: 2
    )
    order.save(validate: false)

    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    get "/api/server/tables", as: :json

    json = JSON.parse(response.body)
    table = json["data"].find { |t| t["number"] == 501 }
    assert_not_nil table["server_name"]
    assert_includes table["server_name"], @waiter.first_name
  end

  # Test 8: Table disponible n'affiche pas de server_name
  test "table disponible a server_name nil" do
    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    get "/api/server/tables", as: :json

    json = JSON.parse(response.body)
    table = json["data"].find { |t| t["number"] == 501 }
    assert_nil table["server_name"]
  end
end
