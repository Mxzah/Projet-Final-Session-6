require "test_helper"

class ComboItemDestroySuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @combo = combos(:combo_one)
    @item1 = items(:item_one)

    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    # Créer un combo item à supprimer
    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item1.id, quantity: 1 }
    }, as: :json
    @combo_item = JSON.parse(response.body)["data"]
  end

  # Test 1: DELETE /api/combo_items/:id supprime le combo item
  test "destroy avec admin retourne success true" do
    delete "/api/combo_items/#{@combo_item['id']}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end

  # Test 2: Après suppression, le combo item n'est plus dans la liste
  test "après suppression le combo item n'est plus dans la liste" do
    combo_item_id = @combo_item["id"]

    delete "/api/combo_items/#{combo_item_id}", as: :json
    assert JSON.parse(response.body)["success"]

    get "/api/combo_items", as: :json
    json = JSON.parse(response.body)
    ids = json["data"].map { |ci| ci["id"] }
    assert_not_includes ids, combo_item_id
  end

  # Test 3: Suppression d'un combo item ne supprime pas le combo
  test "suppression du combo item ne supprime pas le combo" do
    combo_id = @combo_item["combo_id"]

    delete "/api/combo_items/#{@combo_item['id']}", as: :json
    assert JSON.parse(response.body)["success"]

    get "/api/combos", as: :json
    json = JSON.parse(response.body)
    combo_ids = json["data"].map { |c| c["id"] }
    assert_includes combo_ids, combo_id
  end

  # Test 4: Suppression d'un combo item ne supprime pas l'item
  test "suppression du combo item ne supprime pas l'item" do
    item_id = @combo_item["item_id"]

    delete "/api/combo_items/#{@combo_item['id']}", as: :json
    assert JSON.parse(response.body)["success"]

    get "/api/items", as: :json
    json = JSON.parse(response.body)
    item_ids = json["data"].map { |i| i["id"] }
    assert_includes item_ids, item_id
  end
end
