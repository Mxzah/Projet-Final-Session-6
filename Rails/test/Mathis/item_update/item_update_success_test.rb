require "test_helper"

class ItemUpdateSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:entrees)
    @category2 = categories(:plats)

    post "/users/sign_in", params: {
      user: { email: users(:admin_user).email, password: "password123" }
    }, as: :json

    post "/api/items", params: {
      item: { name: "Salade César", description: "Laitue romaine, parmesan", price: 15.99, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }
    @item = JSON.parse(response.body)["data"]
  end

  # Test 1: PATCH /api/items/:id modifie le nom, la description et le prix
  test "update modifie le nom, la description et le prix" do
    patch "/api/items/#{@item['id']}", params: {
      item: { name: "Salade Niçoise", description: "Nouvelle description", price: 17.50 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Salade Niçoise", json["data"]["name"]
    assert_equal "Nouvelle description", json["data"]["description"]
    assert_equal 17.50, json["data"]["price"]
  end

  # Test 2: PATCH /api/items/:id change la catégorie
  test "update change la catégorie" do
    patch "/api/items/#{@item['id']}", params: {
      item: { category_id: @category2.id }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal @category2.id, json["data"]["category_id"]
    assert_equal @category2.name, json["data"]["category_name"]
  end

  # Test 3: PATCH /api/items/:id change l'image
  test "update change l'image" do
    patch "/api/items/#{@item['id']}", params: {
      item: { image: fixture_file_upload("test.png", "image/png") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not_nil json["data"]["image_url"]
  end
end
