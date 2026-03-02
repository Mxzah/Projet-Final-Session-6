require "test_helper"

class ComboCreateFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)

    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json
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

    post "/api/combos", params: {
      combo: { name: "Combo Client", price: 19.99 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 2: Create sans être connecté retourne success false
  test "create sans être connecté retourne success false" do
    delete "/users/sign_out", as: :json

    post "/api/combos", params: {
      combo: { name: "Combo Anonyme", price: 19.99 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # VALIDATION - NOM
  # ══════════════════════════════════════════

  # Test 3: Create sans nom retourne success false
  test "create sans nom retourne success false" do
    post "/api/combos", params: {
      combo: { price: 29.99 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 4: Create avec nom vide retourne success false
  test "create avec nom vide retourne success false" do
    post "/api/combos", params: {
      combo: { name: "", price: 29.99 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 5: Create avec nom > 100 caractères retourne success false
  test "create avec nom trop long retourne success false" do
    long_name = "a" * 101
    post "/api/combos", params: {
      combo: { name: long_name, price: 29.99 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # VALIDATION - DESCRIPTION
  # ══════════════════════════════════════════

  # Test 6: Create avec description > 255 caractères retourne success false
  test "create avec description trop longue retourne success false" do
    long_desc = "b" * 256
    post "/api/combos", params: {
      combo: { name: "Combo Test", description: long_desc, price: 29.99 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # VALIDATION - PRIX
  # ══════════════════════════════════════════

  # Test 7: Create sans prix retourne success false
  test "create sans prix retourne success false" do
    post "/api/combos", params: {
      combo: { name: "Combo Sans Prix" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 8: Create avec prix = 0 retourne success false
  test "create avec prix égal à 0 retourne success false" do
    post "/api/combos", params: {
      combo: { name: "Combo Gratuit", price: 0 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 9: Create avec prix négatif retourne success false
  test "create avec prix négatif retourne success false" do
    post "/api/combos", params: {
      combo: { name: "Combo Négatif", price: -10 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 10: Create avec prix > 9999.99 retourne success false
  test "create avec prix trop élevé retourne success false" do
    post "/api/combos", params: {
      combo: { name: "Combo Trop Cher", price: 10000 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 11: Create avec prix non numérique retourne success false
  test "create avec prix non numérique retourne success false" do
    post "/api/combos", params: {
      combo: { name: "Combo Text", price: "abc" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # VALIDATION - COMBINAISONS
  # ══════════════════════════════════════════

  # Test 12: Create sans aucun champ retourne success false
  test "create sans aucun champ retourne success false" do
    post "/api/combos", params: {
      combo: {}
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
