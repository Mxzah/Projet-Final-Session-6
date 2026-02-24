require "test_helper"

class ItemCreateSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:entrees)

    post "/users/sign_in", params: {
      user: { email: users(:admin_user).email, password: "password123" }
    }, as: :json
  end

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
end
