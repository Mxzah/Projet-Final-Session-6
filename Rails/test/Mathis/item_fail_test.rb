require "test_helper"

class ItemFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)
    @category = categories(:entrees)

    # Connexion admin
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    # Créer un item valide pour les tests update/delete
    post "/api/items", params: {
      item: { name: "Item Test", description: "Description test", price: 20.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }
    @item = JSON.parse(response.body)["data"]
  end

  # ══════════════════════════════════════════
  # CREATE - Tests négatifs
  # ══════════════════════════════════════════

  # Test 1: Create sans nom
  test "create sans nom retourne success false" do
    post "/api/items", params: {
      item: { price: 10.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 2: Create avec nom uniquement d'espaces
  test "create avec nom uniquement d'espaces retourne success false" do
    post "/api/items", params: {
      item: { name: "   ", price: 10.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 3: Create avec nom dépassant 100 caractères
  test "create avec nom trop long retourne success false" do
    post "/api/items", params: {
      item: { name: "A" * 101, price: 10.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 4: Create sans prix
  test "create sans prix retourne success false" do
    post "/api/items", params: {
      item: { name: "Item", category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 5: Create avec prix négatif
  test "create avec prix négatif retourne success false" do
    post "/api/items", params: {
      item: { name: "Item", price: -1, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 6: Create avec prix supérieur à 9999.99
  test "create avec prix supérieur à 9999.99 retourne success false" do
    post "/api/items", params: {
      item: { name: "Item", price: 10000.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 7: Create sans image
  test "create sans image retourne success false" do
    post "/api/items", params: {
      item: { name: "Item", price: 10.00, category_id: @category.id }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 8: Create avec image de type invalide (GIF)
  test "create avec image GIF retourne success false" do
    post "/api/items", params: {
      item: { name: "Item", price: 10.00, category_id: @category.id, image: fixture_file_upload("test.gif", "image/gif") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 9: Create avec description dépassant 255 caractères
  test "create avec description trop longue retourne success false" do
    post "/api/items", params: {
      item: { name: "Item", description: "A" * 256, price: 10.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 11: Create avec catégorie inexistante
  test "create avec catégorie inexistante retourne une erreur" do
    post "/api/items", params: {
      item: { name: "Item", price: 10.00, category_id: 999999, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # READ - Tests négatifs
  # ══════════════════════════════════════════

  # Test 12: Read avec ID inexistant
  test "read avec ID inexistant retourne success false" do
    get "/api/items/999999", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # UPDATE - Tests négatifs
  # ══════════════════════════════════════════

  # Test 13: Update avec nom vide
  test "update avec nom vide retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { name: "" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 14: Update avec nom uniquement d'espaces
  test "update avec nom uniquement d'espaces retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { name: "   " }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 15: Update avec nom dépassant 100 caractères
  test "update avec nom trop long retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { name: "A" * 101 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 16: Update avec prix vide
  test "update avec prix vide retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { price: "" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 17: Update avec prix négatif
  test "update avec prix négatif retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { price: -1 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 18: Update avec prix supérieur à 9999.99
  test "update avec prix supérieur à 9999.99 retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { price: 10000.00 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 19: Update avec image de type invalide (GIF)
  test "update avec image GIF retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { image: fixture_file_upload("test.gif", "image/gif") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 20: Update avec description dépassant 255 caractères
  test "update avec description trop longue retourne success false" do
    patch "/api/items/#{@item['id']}", params: {
      item: { description: "A" * 256 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 22: Update avec catégorie inexistante
  test "update avec catégorie inexistante retourne une erreur" do
    patch "/api/items/#{@item['id']}", params: {
      item: { category_id: 999999 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 23: Update avec ID inexistant
  test "update avec ID inexistant retourne success false" do
    patch "/api/items/999999", params: {
      item: { name: "Nouveau nom" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # DELETE - Tests négatifs
  # ══════════════════════════════════════════

  # Test 24: Delete avec ID inexistant
  test "delete avec ID inexistant retourne success false" do
    delete "/api/items/999999", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # AUTORISATION - Tests non-admin
  # ══════════════════════════════════════════

  # Test 25: Create avec un compte client retourne success false
  test "create avec un compte client retourne success false" do
    # Déconnexion admin
    delete "/users/sign_out", as: :json

    # Connexion client
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    post "/api/items", params: {
      item: { name: "Item Client", price: 10.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Accès réservé aux administrateurs"
  end

  # Test 26: Update avec un compte client retourne success false
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

  # Test 27: Delete avec un compte client retourne success false
  test "delete avec un compte client retourne success false" do
    delete "/users/sign_out", as: :json

    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    delete "/api/items/#{@item['id']}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Accès réservé aux administrateurs"
  end
end
