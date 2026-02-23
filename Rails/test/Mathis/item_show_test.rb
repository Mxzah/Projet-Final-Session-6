require "test_helper"

class ItemShowTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:entrees)

    post "/users/sign_in", params: {
      user: { email: users(:admin_user).email, password: "password123" }
    }, as: :json

    post "/api/items", params: {
      item: { name: "Salade César", description: "Laitue romaine, parmesan", price: 15.99, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }
    @item = JSON.parse(response.body)["data"]
  end

  # Test 1: GET /api/items/:id retourne l'item avec toutes ses propriétés
  test "read retourne l'item avec toutes ses propriétés" do
    get "/api/items/#{@item['id']}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    data = json["data"]
    assert_equal "Salade César", data["name"]
    assert_equal "Laitue romaine, parmesan", data["description"]
    assert_equal 15.99, data["price"]
    assert_equal @category.id, data["category_id"]
    assert_equal @category.name, data["category_name"]
    assert_not_nil data["image_url"]
    assert_not_nil data["created_at"]
  end

  # Test 2: Read avec ID inexistant retourne success false
  test "read avec ID inexistant retourne success false" do
    get "/api/items/999999", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
