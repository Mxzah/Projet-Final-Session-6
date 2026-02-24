require "test_helper"

class ItemShowFailTest < ActionDispatch::IntegrationTest
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

  # Test 2: Read avec ID inexistant retourne success false
  test "read avec ID inexistant retourne success false" do
    get "/api/items/999999", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
