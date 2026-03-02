require "test_helper"

class ComboItemDestroyFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)
    @combo = combos(:combo_one)
    @item1 = items(:item_one)

    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    # Créer un combo item pour les tests
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item1.id, quantity: 1 }
    }, as: :json
    @combo_item = JSON.parse(response.body)["data"]
  end

  # ══════════════════════════════════════════
  # AUTORISATION
  # ══════════════════════════════════════════

  # Test 1: Delete avec un compte client retourne success false
  test "destroy avec un compte client retourne success false" do
    delete "/users/sign_out", as: :json
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    delete "/api/combo_items/#{@combo_item['id']}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 2: Delete sans être connecté retourne success false
  test "destroy sans être connecté retourne success false" do
    delete "/users/sign_out", as: :json

    delete "/api/combo_items/#{@combo_item['id']}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # VALIDATION - ID INEXISTANT
  # ══════════════════════════════════════════

  # Test 3: Delete avec id inexistant retourne 404
  test "destroy avec id inexistant retourne 404" do
    delete "/api/combo_items/999999", as: :json

    assert_response :not_found
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 4: Delete avec id = 0 retourne not found
  test "destroy avec id égal à 0 retourne not found" do
    delete "/api/combo_items/0", as: :json

    assert_response :not_found
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 5: Delete avec id négatif retourne not found
  test "destroy avec id négatif retourne not found" do
    delete "/api/combo_items/-1", as: :json

    assert_response :not_found
    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
