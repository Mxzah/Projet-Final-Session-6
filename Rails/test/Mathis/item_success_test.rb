require "test_helper"

class ItemSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    @category = categories(:entrees)
    @category2 = categories(:plats)

    # Connexion
    post "/users/sign_in", params: {
      user: { email: @user.email, password: "password123" }
    }, as: :json

    # Créer des items pour les tests
    @image_jpg = fixture_file_upload("test.jpg", "image/jpeg")
    @image_png = fixture_file_upload("test.png", "image/png")

    post "/api/items", params: {
      item: { name: "Salade César", description: "Laitue romaine, parmesan", price: 15.99, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }
    @item1 = JSON.parse(response.body)["data"]

    post "/api/items", params: {
      item: { name: "Poulet Grillé", description: "Poulet mariné aux herbes", price: 24.50, category_id: @category2.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }
    @item2 = JSON.parse(response.body)["data"]

    post "/api/items", params: {
      item: { name: "Soupe à l'oignon", description: "Soupe gratinée", price: 12.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }
    @item3 = JSON.parse(response.body)["data"]
  end

  # ── List ──

  # Test 1: GET /api/items retourne tous les items
  test "list retourne tous les items avec success true et status 200" do
    get "/api/items", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
    assert json["data"].length >= 3
  end

  # ── Read ──

  # Test 2: GET /api/items/:id retourne l'item avec toutes ses propriétés
  test "read retourne l'item avec toutes ses propriétés" do
    get "/api/items/#{@item1['id']}", as: :json

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

  # ── Create ──

  # Test 3: POST /api/items avec tous les champs valides (image JPG)
  test "create avec champs valides et image JPG retourne 201" do
    post "/api/items", params: {
      item: { name: "Tartare de Saumon", description: "Saumon frais", price: 18.50, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :created
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Tartare de Saumon", json["data"]["name"]
    assert_equal 18.50, json["data"]["price"]
  end

  # Test 4: POST /api/items sans description (optionnelle)
  test "create sans description crée l'item" do
    post "/api/items", params: {
      item: { name: "Bruschetta", price: 11.00, category_id: @category.id, image: fixture_file_upload("test.jpg", "image/jpeg") }
    }

    assert_response :created
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Bruschetta", json["data"]["name"]
  end

  # Test 5: POST /api/items avec image PNG
  test "create avec image PNG crée l'item" do
    post "/api/items", params: {
      item: { name: "Carpaccio", description: "Boeuf tranché fin", price: 16.00, category_id: @category.id, image: fixture_file_upload("test.png", "image/png") }
    }

    assert_response :created
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not_nil json["data"]["image_url"]
  end

  # ── Update ──

  # Test 6: PATCH /api/items/:id modifie le nom, la description et le prix
  test "update modifie le nom, la description et le prix" do
    patch "/api/items/#{@item1['id']}", params: {
      item: { name: "Salade Niçoise", description: "Nouvelle description", price: 17.50 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Salade Niçoise", json["data"]["name"]
    assert_equal "Nouvelle description", json["data"]["description"]
    assert_equal 17.50, json["data"]["price"]
  end

  # Test 7: PATCH /api/items/:id change la catégorie
  test "update change la catégorie" do
    patch "/api/items/#{@item1['id']}", params: {
      item: { category_id: @category2.id }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal @category2.id, json["data"]["category_id"]
    assert_equal @category2.name, json["data"]["category_name"]
  end

  # Test 8: PATCH /api/items/:id change l'image
  test "update change l'image" do
    patch "/api/items/#{@item1['id']}", params: {
      item: { image: fixture_file_upload("test.png", "image/png") }
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not_nil json["data"]["image_url"]
  end

  # ── Delete ──

  # Test 9: DELETE /api/items/:id soft-delete l'item
  test "delete soft-delete l'item avec status 200" do
    delete "/api/items/#{@item1['id']}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    # Vérifier que deleted_at est rempli en DB
    item = Item.unscoped.find(@item1["id"])
    assert_not_nil item.deleted_at
  end

  # Test 10: L'item soft-deleted n'apparaît plus dans la liste
  test "item soft-deleted n'apparaît plus dans GET /api/items" do
    delete "/api/items/#{@item1['id']}", as: :json
    assert_response :ok

    get "/api/items", as: :json
    json = JSON.parse(response.body)
    ids = json["data"].map { |i| i["id"] }
    assert_not_includes ids, @item1["id"]
  end

  # ── Search ──

  # Test 11: GET /api/items?search=poulet retourne les items correspondants
  test "search retourne uniquement les items dont le nom contient le terme" do
    get "/api/items", params: { search: "Poulet" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1
    json["data"].each do |item|
      assert_match(/poulet/i, item["name"])
    end
  end

  # ── Sort ──

  # Test 12: GET /api/items?sort=asc retourne les items triés par prix croissant
  test "sort asc retourne les items triés par prix croissant" do
    get "/api/items", params: { sort: "asc" }

    assert_response :ok
    json = JSON.parse(response.body)
    prices = json["data"].map { |i| i["price"] }
    assert_equal prices, prices.sort
  end

  # Test 13: GET /api/items?sort=desc retourne les items triés par prix décroissant
  test "sort desc retourne les items triés par prix décroissant" do
    get "/api/items", params: { sort: "desc" }

    assert_response :ok
    json = JSON.parse(response.body)
    prices = json["data"].map { |i| i["price"] }
    assert_equal prices, prices.sort.reverse
  end

  # ── Filter ──

  # Test 14: GET /api/items?price_min=10&price_max=16 retourne les items dans la fourchette
  test "filter par prix retourne uniquement les items dans la fourchette" do
    get "/api/items", params: { price_min: 10, price_max: 16 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    json["data"].each do |item|
      assert item["price"] >= 10, "Prix #{item['price']} est inférieur à 10"
      assert item["price"] <= 16, "Prix #{item['price']} est supérieur à 16"
    end
  end
end
