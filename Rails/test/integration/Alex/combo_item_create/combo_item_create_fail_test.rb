require "test_helper"

class ComboItemCreateFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)
    @combo = combos(:combo_one)
    @combo2 = combos(:combo_two)
    @item1 = items(:item_one)
    @item2 = items(:item_two)

    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    # Créer un combo item pour les tests de doublon
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item1.id, quantity: 1 }
    }, as: :json
    @combo_item = JSON.parse(response.body)["data"]
  end

  # ══════════════════════════════════════════
  # AUTORISATION
  # ══════════════════════════════════════════

  # Test 1: Create avec un compte client retourne success false
  test "create avec un compte client retourne success false" do
    delete "/users/sign_out", as: :json
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item2.id, quantity: 1 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 2: Create sans être connecté retourne success false
  test "create sans être connecté retourne success false" do
    delete "/users/sign_out", as: :json

    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item2.id, quantity: 1 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # VALIDATION - QUANTITÉ
  # ══════════════════════════════════════════

  # Test 3: Create sans quantité retourne success false
  test "create sans quantité retourne success false" do
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item2.id }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 4: Create avec quantité = 0 retourne success false
  test "create avec quantité égale à 0 retourne success false" do
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item2.id, quantity: 0 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 5: Create avec quantité négative retourne success false
  test "create avec quantité négative retourne success false" do
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item2.id, quantity: -1 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 6: Create avec quantité > 10 retourne success false
  test "create avec quantité supérieure à 10 retourne success false" do
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item2.id, quantity: 11 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 7: Create avec quantité décimale retourne success false
  test "create avec quantité décimale retourne success false" do
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item2.id, quantity: 2.5 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # VALIDATION - DOUBLON
  # ══════════════════════════════════════════

  # Test 8: Create avec item déjà dans le combo (doublon) retourne success false
  test "create avec item déjà dans le combo retourne success false" do
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item1.id, quantity: 2 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any? { |e| e.downcase.include?("existe") || e.downcase.include?("taken") || e.downcase.include?("already") }
  end

  # ══════════════════════════════════════════
  # VALIDATION - RELATIONS
  # ══════════════════════════════════════════

  # Test 9: Create sans combo_id retourne success false
  test "create sans combo_id retourne success false" do
    post "/api/combo_items", params: {
      combo_item: { item_id: @item2.id, quantity: 1 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 10: Create sans item_id retourne success false
  test "create sans item_id retourne success false" do
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, quantity: 1 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 11: Create avec combo_id inexistant retourne success false
  test "create avec combo_id inexistant retourne success false" do
    post "/api/combo_items", params: {
      combo_item: { combo_id: 999999, item_id: @item2.id, quantity: 1 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 12: Create avec item_id inexistant retourne success false
  test "create avec item_id inexistant retourne success false" do
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: 999999, quantity: 1 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 13: Create sans aucun champ retourne success false
  test "create sans aucun champ retourne success false" do
    post "/api/combo_items", params: {
      combo_item: {}
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
