# frozen_string_literal: true

require "test_helper"

class VibeUpdateFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @vibe  = vibes(:vibe_zen)
    post "/users/sign_in", params: { user: { email: @admin.email, password: "password123" } }, as: :json
  end

  # Test 1: Non authentifié → erreur
  test "update retourne erreur si non authentifié" do
    delete "/users/sign_out", as: :json

    put "/api/vibes/#{@vibe.id}", params: { vibe: { name: "Modifié" } }, as: :json

    assert_response :ok
    assert_not JSON.parse(response.body)["success"]
  end

  # Test 2: Client normal → erreur
  test "update retourne erreur si l utilisateur n est pas admin" do
    delete "/users/sign_out", as: :json
    post "/users/sign_in", params: { user: { email: users(:valid_user).email, password: "password123" } }, as: :json

    put "/api/vibes/#{@vibe.id}", params: { vibe: { name: "Hacked" } }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 3: Nom en double → validation fail
  test "update retourne erreur si le nom est déjà utilisé" do
    existing_name = vibes(:vibe_festive).name

    put "/api/vibes/#{@vibe.id}", params: { vibe: { name: existing_name } }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 4: Nom vide → validation fail
  test "update retourne erreur si name est vide" do
    put "/api/vibes/#{@vibe.id}", params: { vibe: { name: "" } }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end
end
