# frozen_string_literal: true

require "test_helper"

class TableStatsFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)
    @cook = users(:cook_user)
  end

  # ══════════════════════════════════════════
  # AUTORISATION
  # ══════════════════════════════════════════

  # Test 1: Un client ne peut pas accéder aux stats
  test "client ne peut pas accéder aux stats" do
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    get "/api/tables/stats", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 2: Un cuisinier ne peut pas accéder aux stats
  test "cuisinier ne peut pas accéder aux stats" do
    post "/users/sign_in", params: {
      user: { email: @cook.email, password: "password123" }
    }, as: :json

    get "/api/tables/stats", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 3: Un utilisateur non connecté ne peut pas accéder aux stats
  test "utilisateur non connecté ne peut pas accéder aux stats" do
    get "/api/tables/stats", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # VALIDATION DES DATES
  # ══════════════════════════════════════════

  # Test 4: Stats avec start_date invalide
  test "stats avec start_date invalide retourne success false" do
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    get "/api/tables/stats", params: { start_date: "invalide" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 5: Stats avec end_date invalide
  test "stats avec end_date invalide retourne success false" do
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    get "/api/tables/stats", params: { end_date: "invalide" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 6: Stats avec end_date avant start_date
  test "stats avec end_date avant start_date retourne success false" do
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    get "/api/tables/stats", params: {
      start_date: "2025-12-31",
      end_date: "2024-01-01"
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # AUTORISATION — SERVEUR
  # ══════════════════════════════════════════

  # Test 7: Un serveur ne peut pas accéder aux stats
  test "serveur ne peut pas accéder aux stats" do
    waiter = users(:waiter_user)
    post "/users/sign_in", params: {
      user: { email: waiter.email, password: "password123" }
    }, as: :json

    get "/api/tables/stats", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
