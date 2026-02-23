require "test_helper"

class ItemCreateTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:entrees)
    @client = users(:valid_user)

    post "/users/sign_in", params: {
      user: { email: users(:admin_user).email, password: "password123" }
    }, as: :json
  end

  # ── Tests positifs ──

  # Test 1: POST /api/items avec tous les champs valides (image JPG)
  test "create avec champs valides et image JPG retourne 200" do
    post "/api/items", params: {
      item: { name: "Tartare de Saumon", description: "Saumon frais", price: 18.50, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Tartare de Saumon", json["data"]["name"]
    assert_equal 18.50, json["data"]["price"]
  end

  # Test 2: POST /api/items sans description (optionnelle)
  test "create sans description crée l'item" do
    post "/api/items", params: {
      item: { name: "Bruschetta", price: 11.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Bruschetta", json["data"]["name"]
  end

  # Test 3: POST /api/items avec image PNG
  test "create avec image PNG crée l'item" do
    post "/api/items", params: {
      item: { name: "Carpaccio", description: "Boeuf tranché fin", price: 16.00, category_id: @category.id, image: fixture_file_upload("test.png", "image/png") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not_nil json["data"]["image_url"]
  end

  # ── Tests négatifs ──

  # Test 4: Create sans nom
  test "create sans nom retourne success false" do
    post "/api/items", params: {
      item: { price: 10.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 5: Create avec nom uniquement d'espaces
  test "create avec nom uniquement d'espaces retourne success false" do
    post "/api/items", params: {
      item: { name: "   ", price: 10.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 6: Create avec nom dépassant 100 caractères
  test "create avec nom trop long retourne success false" do
    post "/api/items", params: {
      item: { name: "A" * 101, price: 10.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 7: Create sans prix
  test "create sans prix retourne success false" do
    post "/api/items", params: {
      item: { name: "Item", category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 8: Create avec prix négatif
  test "create avec prix négatif retourne success false" do
    post "/api/items", params: {
      item: { name: "Item", price: -1, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 9: Create avec prix supérieur à 9999.99
  test "create avec prix supérieur à 9999.99 retourne success false" do
    post "/api/items", params: {
      item: { name: "Item", price: 10000.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 10: Create sans image
  test "create sans image retourne success false" do
    post "/api/items", params: {
      item: { name: "Item", price: 10.00, category_id: @category.id }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 11: Create avec image de type invalide (GIF)
  test "create avec image GIF retourne success false" do
    post "/api/items", params: {
      item: { name: "Item", price: 10.00, category_id: @category.id, image: fixture_file_upload("test.gif", "image/gif") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 12: Create avec description dépassant 255 caractères
  test "create avec description trop longue retourne success false" do
    post "/api/items", params: {
      item: { name: "Item", description: "A" * 256, price: 10.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 13: Create avec catégorie inexistante
  test "create avec catégorie inexistante retourne une erreur" do
    post "/api/items", params: {
      item: { name: "Item", price: 10.00, category_id: 999999, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ── Autorisation ──

  # Test 14: Create avec un compte client retourne success false
  test "create avec un compte client retourne success false" do
    delete "/users/sign_out", as: :json

    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    post "/api/items", params: {
      item: { name: "Item Client", price: 10.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Access restricted to administrators"
  end
end
