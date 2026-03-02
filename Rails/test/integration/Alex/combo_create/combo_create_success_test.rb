require "test_helper"

class ComboCreateSuccessTest < ActionDispatch::IntegrationTest
  setup do
    post "/users/sign_in", params: {
      user: { email: users(:admin_user).email, password: "password123" }
    }, as: :json
  end

  # Test 1: POST /api/combos avec tous les champs valides
  test "create avec tous les champs valides retourne success true" do
    post "/api/combos", params: {
      combo: { name: "Menu Dégustation", description: "Entrée, plat, dessert", price: 59.99 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Menu Dégustation", json["data"]["name"]
    assert_equal "Entrée, plat, dessert", json["data"]["description"]
    assert_equal 59.99, json["data"]["price"]
  end

  # Test 2: POST /api/combos sans description (optionnelle)
  test "create sans description retourne success true" do
    post "/api/combos", params: {
      combo: { name: "Combo Sans Desc", price: 25.99 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_nil json["data"]["description"]
  end

  # Test 3: POST /api/combos avec prix minimum (0.01)
  test "create avec prix minimum (0.01) retourne success true" do
    post "/api/combos", params: {
      combo: { name: "Combo Économique", price: 0.01 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0.01, json["data"]["price"]
  end

  # Test 4: POST /api/combos avec prix maximum (9999.99)
  test "create avec prix maximum (9999.99) retourne success true" do
    post "/api/combos", params: {
      combo: { name: "Combo Premium", price: 9999.99 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 9999.99, json["data"]["price"]
  end

  # Test 5: POST /api/combos avec nom de 100 caractères (limite)
  test "create avec nom de 100 caractères retourne success true" do
    long_name = "a" * 100
    post "/api/combos", params: {
      combo: { name: long_name, price: 25.99 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 100, json["data"]["name"].length
  end

  # Test 6: POST /api/combos avec description de 255 caractères (limite)
  test "create avec description de 255 caractères retourne success true" do
    long_desc = "b" * 255
    post "/api/combos", params: {
      combo: { name: "Combo Long Desc", description: long_desc, price: 35.99 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 255, json["data"]["description"].length
  end
end
