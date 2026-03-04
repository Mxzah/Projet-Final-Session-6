require "test_helper"

class VibeIndexFailTest < ActionDispatch::IntegrationTest
  # Test 1: Unauthenticated user still gets success (route is public)
  test "index sans authentification retourne quand même success true" do
    get "/api/vibes", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
  end

  # Test 2: Client ne voit pas les vibes archivées
  test "index client ne voit pas les vibes soft-deleted" do
    post "/users/sign_in", params: { user: { email: users(:valid_user).email, password: "password123" } }, as: :json

    get "/api/vibes", as: :json

    json = JSON.parse(response.body)
    archived_ids = json["data"].select { |v| v["deleted_at"].present? }.map { |v| v["id"] }
    assert_empty archived_ids
  end
end
