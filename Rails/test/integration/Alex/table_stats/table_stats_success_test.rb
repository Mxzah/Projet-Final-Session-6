# frozen_string_literal: true

require "test_helper"

class TableStatsSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)

    # Connexion admin
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json
  end

  # ══════════════════════════════════════════
  # AUTORISATION
  # ══════════════════════════════════════════

  # Test 1: Un admin peut accéder aux stats des tables
  test "admin peut accéder aux stats des tables" do
    get "/api/tables/stats", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end

  # ══════════════════════════════════════════
  # STRUCTURE DE LA RÉPONSE
  # ══════════════════════════════════════════

  # Test 2: La réponse contient les colonnes attendues
  test "stats retourne les colonnes attendues" do
    get "/api/tables/stats", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    columns = json["data"]["columns"]
    assert_kind_of Array, columns

    column_keys = columns.map { |c| c["key"] }
    assert_includes column_keys, "table_number"
    assert_includes column_keys, "capacity"
    assert_includes column_keys, "nb_orders"
    assert_includes column_keys, "nb_distinct_clients"
    assert_includes column_keys, "avg_people"
    assert_includes column_keys, "avg_duration_min"
    assert_includes column_keys, "top_vibe"
    assert_includes column_keys, "usage_pct"
  end

  # Test 3: La réponse contient des rows
  test "stats retourne des rows" do
    get "/api/tables/stats", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    rows = json["data"]["rows"]
    assert_kind_of Array, rows
  end

  # Test 4: Chaque colonne a un label
  test "chaque colonne a un key et un label" do
    get "/api/tables/stats", as: :json

    json = JSON.parse(response.body)
    json["data"]["columns"].each do |col|
      assert col.key?("key"), "Colonne sans key"
      assert col.key?("label"), "Colonne sans label"
    end
  end

  # ══════════════════════════════════════════
  # FILTRES PAR DATE
  # ══════════════════════════════════════════

  # Test 5: Stats avec start_date valide
  test "stats avec start_date valide retourne success true" do
    get "/api/tables/stats", params: { start_date: "2024-01-01" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end

  # Test 6: Stats avec end_date valide
  test "stats avec end_date valide retourne success true" do
    get "/api/tables/stats", params: { end_date: "2025-12-31" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end

  # Test 7: Stats avec plage de dates valide
  test "stats avec plage de dates valide retourne success true" do
    get "/api/tables/stats", params: {
      start_date: "2024-01-01",
      end_date: "2025-12-31"
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end

  # ══════════════════════════════════════════
  # FILTRE PAR SERVEUR (category_ids)
  # ══════════════════════════════════════════

  # Test 8: Stats avec category_ids (filtre par serveur)
  test "stats avec category_ids retourne success true" do
    waiter = users(:waiter_user)
    get "/api/tables/stats", params: {
      category_ids: [ waiter.id ]
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end

  # Test 9: Stats avec category_ids inexistant retourne des rows vides
  test "stats avec category_ids inexistant retourne rows vides" do
    get "/api/tables/stats", params: {
      category_ids: [ 999999 ]
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    json["data"]["rows"].each do |row|
      assert_equal 0, row["nb_orders"].to_i
    end
  end

  # Test 10: Stats avec combinaison dates + category_ids
  test "stats avec dates et category_ids retourne success true" do
    waiter = users(:waiter_user)
    get "/api/tables/stats", params: {
      start_date: "2024-01-01",
      end_date: "2025-12-31",
      category_ids: [ waiter.id ]
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end
end
