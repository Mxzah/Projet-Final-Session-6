require "test_helper"

class ItemDestroyFailTest < ActionDispatch::IntegrationTest
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

  # Test 3: Delete avec ID inexistant retourne success false
  test "delete avec ID inexistant retourne success false" do
    delete "/api/items/999999", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

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
