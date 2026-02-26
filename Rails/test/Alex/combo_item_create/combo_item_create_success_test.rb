require "test_helper"

class ComboItemCreateSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @combo = combos(:combo_one)
    @item1 = items(:item_one)
    @item2 = items(:item_two)
    @item3 = items(:item_three)

    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json
  end

  # Test 1: POST /api/combo_items avec tous les champs valides
  test "create avec champs valides retourne success true" do
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item1.id, quantity: 2 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal @combo.id, json["data"]["combo_id"]
    assert_equal @item1.id, json["data"]["item_id"]
    assert_equal 2, json["data"]["quantity"]
  end

  # Test 2: POST /api/combo_items avec quantité minimum (1)
  test "create avec quantité minimum (1) retourne success true" do
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item1.id, quantity: 1 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 1, json["data"]["quantity"]
  end

  # Test 3: POST /api/combo_items avec quantité maximum (10)
  test "create avec quantité maximum (10) retourne success true" do
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item1.id, quantity: 10 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 10, json["data"]["quantity"]
  end

  # Test 4: POST /api/combo_items retourne les noms combo et item
  test "create retourne les noms combo et item" do
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item1.id, quantity: 1 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal @combo.name, json["data"]["combo_name"]
    assert_equal @item1.name, json["data"]["item_name"]
  end

  # Test 5: POST /api/combo_items - même item dans combos différents
  test "même item peut être dans des combos différents" do
    combo2 = combos(:combo_two)

    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item1.id, quantity: 1 }
    }, as: :json
    assert JSON.parse(response.body)["success"]

    post "/api/combo_items", params: {
      combo_item: { combo_id: combo2.id, item_id: @item1.id, quantity: 1 }
    }, as: :json
    assert JSON.parse(response.body)["success"]
  end

  # Test 6: POST /api/combo_items - plusieurs items différents dans même combo
  test "plusieurs items différents dans même combo" do
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item1.id, quantity: 1 }
    }, as: :json
    assert JSON.parse(response.body)["success"]

    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item2.id, quantity: 2 }
    }, as: :json
    assert JSON.parse(response.body)["success"]

    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item3.id, quantity: 3 }
    }, as: :json
    assert JSON.parse(response.body)["success"]
  end
end
