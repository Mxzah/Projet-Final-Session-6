# frozen_string_literal: true

require "test_helper"

class OrderStatsFailTest < ActionDispatch::IntegrationTest
  # Test 1: Non authentifié → success false
  test "stats retourne erreur si non authentifié" do
    get "/api/orders/stats", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 2: Client ne peut pas accéder aux stats
  test "stats retourne erreur si client" do
    post "/users/sign_in", params: { user: { email: users(:valid_user).email, password: "password123" } }, as: :json

    get "/api/orders/stats", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"].join, "administrateurs"
  end

  # Test 3: Serveur ne peut pas accéder aux stats
  test "stats retourne erreur si serveur" do
    post "/users/sign_in", params: { user: { email: users(:waiter_user).email, password: "password123" } }, as: :json

    get "/api/orders/stats", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"].join, "administrateurs"
  end
end
