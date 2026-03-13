# frozen_string_literal: true

require "test_helper"

class ComboIndexFailTest < ActionDispatch::IntegrationTest
  setup do
    @combo1 = combos(:combo_one)
    @combo2 = combos(:combo_two)
    @combo3 = combos(:combo_three)
  end

  # ══════════════════════════════════════════
  # VISIBILITÉ — DISPONIBILITÉ
  # ══════════════════════════════════════════

  # Test 1: Sans être connecté, un combo sans disponibilité active ne s'affiche pas
  test "combo sans disponibilité active n'apparaît pas pour un non connecté" do
    get "/api/combos", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    # Les combos sans disponibilité active ne doivent pas apparaître
    names = json["data"].map { |c| c["name"] }
    assert_not_includes names, @combo1.name, "Un combo sans disponibilité ne devrait pas être visible"
  end

  # Test 2: Client connecté ne voit pas les combos sans disponibilité active
  test "client connecté ne voit pas les combos sans disponibilité" do
    client = users(:valid_user)
    post "/users/sign_in", params: {
      user: { email: client.email, password: "password123" }
    }, as: :json

    get "/api/combos", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    names = json["data"].map { |c| c["name"] }
    assert_not_includes names, @combo1.name
  end

  # Test 3: Client connecté avec admin=true ne contourne pas la restriction
  test "client avec admin=true ne contourne pas la restriction de disponibilité" do
    client = users(:valid_user)
    post "/users/sign_in", params: {
      user: { email: client.email, password: "password123" }
    }, as: :json

    get "/api/combos", params: { admin: "true" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    # Le client ne devrait avoir aucun accès admin
    json["data"].each do |combo|
      assert_nil combo["deleted_at"]
    end
  end
end
