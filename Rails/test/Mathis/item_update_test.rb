require "test_helper"

class ItemUpdateTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:entrees)
    @category2 = categories(:plats)
    @client = users(:valid_user)

    post "/users/sign_in", params: {
      user: { email: users(:admin_user).email, password: "password123" }
    }, as: :json

    post "/api/items", params: {
      item: { name: "Salade César", description: "Laitue romaine, parmesan", price: 15.99, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }
    @item = JSON.parse(response.body)["data"]
  end

  # ── Tests positifs ──

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

  # ── Tests négatifs ──

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

  # ── Autorisation ──

  # Test 14: Update avec un compte client retourne success false
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
    assert_includes json["errors"], "Accès réservé aux administrateurs"
  end
end
