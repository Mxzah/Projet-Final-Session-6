# frozen_string_literal: true

require "test_helper"

class VibeRestoreFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin         = users(:admin_user)
    @archived_vibe = vibes(:vibe_archived)
    post "/users/sign_in", params: { user: { email: @admin.email, password: "password123" } }, as: :json
  end

  # Test 1: Non authentifié → erreur
  test "restore retourne erreur si non authentifié" do
    delete "/users/sign_out", as: :json

    patch "/api/vibes/#{@archived_vibe.id}/restore", as: :json

    assert_response :ok
    assert_not JSON.parse(response.body)["success"]
  end

  # Test 2: Client normal → erreur
  test "restore retourne erreur si l utilisateur n est pas admin" do
    delete "/users/sign_out", as: :json
    post "/users/sign_in", params: { user: { email: users(:valid_user).email, password: "password123" } }, as: :json

    patch "/api/vibes/#{@archived_vibe.id}/restore", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
