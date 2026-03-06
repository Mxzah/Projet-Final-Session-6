# frozen_string_literal: true

require "test_helper"

class VibeCreateFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    post "/users/sign_in", params: { user: { email: @admin.email, password: "password123" } }, as: :json
  end

  # Test 1: Non authentifié → erreur
  test "create retourne erreur si non authentifié" do
    delete "/users/sign_out", as: :json

    post "/api/vibes", params: { vibe: { name: "Nouvelle", color: "#000000" } }, as: :json

    assert_response :ok
    assert_not JSON.parse(response.body)["success"]
  end

  # Test 2: Client normal (non-admin) → erreur
  test "create retourne erreur si l utilisateur n est pas admin" do
    delete "/users/sign_out", as: :json
    post "/users/sign_in", params: { user: { email: users(:valid_user).email, password: "password123" } }, as: :json

    post "/api/vibes", params: { vibe: { name: "NouvVibe", color: "#FFFFFF" } }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 3: Nom manquant → validation fail
  test "create retourne erreur si name est absent" do
    post "/api/vibes", params: { vibe: { color: "#FF0000" } }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 4: Couleur manquante → validation fail
  test "create retourne erreur si color est absent" do
    post "/api/vibes", params: { vibe: { name: "Sans couleur" } }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 5: Nom en double → validation fail (uniqueness)
  test "create retourne erreur si le nom existe déjà" do
    existing_name = vibes(:vibe_zen).name

    post "/api/vibes", params: { vibe: { name: existing_name, color: "#123456" } }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 6: Nom trop long (> 50 chars) → validation fail
  test "create retourne erreur si le nom dépasse 50 caractères" do
    post "/api/vibes", params: { vibe: { name: "a" * 51, color: "#AABBCC" } }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end
end
