require "test_helper"

class ComboItemIndexSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @combo = combos(:combo_one)
    @item1 = items(:item_one)

    # Créer un combo item via admin
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item1.id, quantity: 2 }
    }, as: :json
  end

  # Test 1: GET /api/combo_items sans être connecté retourne la liste
  test "index sans être connecté retourne success true" do
    delete "/users/sign_out", as: :json

    get "/api/combo_items", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_kind_of Array, json["data"]
  end

  # Test 2: GET /api/combo_items avec admin retourne la liste
  test "index avec admin retourne success true" do
    get "/api/combo_items", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end

  # Test 3: GET /api/combo_items retourne les champs attendus
  test "index retourne les champs attendus" do
    get "/api/combo_items", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    combo_item = json["data"].first
    assert combo_item.key?("id")
    assert combo_item.key?("combo_id")
    assert combo_item.key?("combo_name")
    assert combo_item.key?("item_id")
    assert combo_item.key?("item_name")
    assert combo_item.key?("quantity")
  end

  # Test 4: GET /api/combo_items retourne le nom du combo
  test "index retourne le nom du combo" do
    get "/api/combo_items", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    combo_item = json["data"].find { |ci| ci["combo_id"] == @combo.id }
    assert_equal @combo.name, combo_item["combo_name"]
  end

  # Test 5: GET /api/combo_items retourne le nom de l'item
  test "index retourne le nom de l'item" do
    get "/api/combo_items", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    combo_item = json["data"].find { |ci| ci["item_id"] == @item1.id }
    assert_equal @item1.name, combo_item["item_name"]
  end
end
