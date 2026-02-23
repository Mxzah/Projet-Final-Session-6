require "test_helper"

class ItemDestroyTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:entrees)
    @client = users(:valid_user)

    post "/users/sign_in", params: {
      user: { email: users(:admin_user).email, password: "password123" }
    }, as: :json

    post "/api/items", params: {
      item: { name: "Item Test", description: "Description test", price: 20.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }
    @item = JSON.parse(response.body)["data"]
  end

  # ── Tests positifs ──

  # Test 1: DELETE /api/items/:id soft-delete l'item
  test "delete soft-delete l'item avec status 200" do
    delete "/api/items/#{@item['id']}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    item = Item.unscoped.find(@item["id"])
    assert_not_nil item.deleted_at
  end

  # Test 2: L'item soft-deleted n'apparaît plus dans la liste (client)
  test "item soft-deleted n'apparaît plus dans GET /api/items" do
    delete "/api/items/#{@item['id']}", as: :json
    assert_response :ok

    delete "/users/sign_out", as: :json

    get "/api/items", as: :json
    json = JSON.parse(response.body)
    ids = json["data"].map { |i| i["id"] }
    assert_not_includes ids, @item["id"]
  end

  # ── Tests négatifs ──

  # Test 3: Delete avec ID inexistant retourne success false
  test "delete avec ID inexistant retourne success false" do
    delete "/api/items/999999", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ── Autorisation ──

  # Test 4: Delete avec un compte client retourne success false
  test "delete avec un compte client retourne success false" do
    delete "/users/sign_out", as: :json

    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    delete "/api/items/#{@item['id']}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Access restricted to administrators"
  end
end
