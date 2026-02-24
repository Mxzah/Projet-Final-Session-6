require "test_helper"

class ItemUpdateFailTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:entrees)
    @client = users(:valid_user)

    post "/users/sign_in", params: {
      user: { email: users(:admin_user).email, password: "password123" }
    }, as: :json

    post "/api/items", params: {
      item: { name: "Salade César", description: "Laitue romaine, parmesan", price: 15.99, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }
    @item = JSON.parse(response.body)["data"]
  end

  # Test 4: Update avec nom vide
  test "update avec nom vide retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { name: "" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 5: Update avec nom uniquement d'espaces
  test "update avec nom uniquement d'espaces retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { name: "   " }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 6: Update avec nom dépassant 100 caractères
  test "update avec nom trop long retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { name: "A" * 101 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 7: Update avec prix vide
  test "update avec prix vide retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { price: "" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 8: Update avec prix négatif
  test "update avec prix négatif retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { price: -1 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 9: Update avec prix supérieur à 9999.99
  test "update avec prix supérieur à 9999.99 retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { price: 10000.00 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 10: Update avec image de type invalide (GIF)
  test "update avec image GIF retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { image: fixture_file_upload("test.gif", "image/gif") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 11: Update avec description dépassant 255 caractères
  test "update avec description trop longue retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { description: "A" * 256 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 12: Update avec catégorie inexistante
  test "update avec catégorie inexistante retourne une erreur" do
    patch "/api/items/#{@item['id']}", params: {
      item: { category_id: 999999 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 13: Update avec ID inexistant
  test "update avec ID inexistant retourne success false" do
    patch "/api/items/999999", params: {
      item: { name: "Nouveau nom" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 14: Update d'un item archivé retourne success false
  test "update d'un item archivé retourne success false" do
    delete "/api/items/#{@item['id']}", as: :json
    assert_response :ok

    patch "/api/items/#{@item['id']}", params: {
      item: { name: "Modification interdite" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Cannot update an archived item"
  end

  # Test 15: Update avec un compte client retourne success false
  test "update avec un compte client retourne success false" do
    delete "/users/sign_out", as: :json

    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    patch "/api/items/#{@item['id']}", params: {
      item: { name: "Modifié par client" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Access restricted to administrators"
  end
end
