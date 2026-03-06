# frozen_string_literal: true

require "test_helper"

class ItemIndexSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:entrees)

    post "/users/sign_in", params: {
      user: { email: users(:admin_user).email, password: "password123" }
    }, as: :json

    post "/api/items", params: {
      item: {
        name: "Salade César", description: "Laitue romaine, parmesan",
        price: 15.99, category_id: @category.id,
        image: fixture_file_upload("test.jpg", "image/jpeg")
      }
    }
    @item = JSON.parse(response.body)["data"]

    # Ajouter une availability active pour que l'item apparaisse dans le menu
    Availability.create!(
      available_type: "Item",
      available_id: @item["id"],
      start_at: Time.current.beginning_of_minute,
      end_at: nil
    )
  end

  # Test 1: GET /api/items retourne tous les items
  test "list retourne tous les items avec success true et status 200" do
    get "/api/items"

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
    assert json["data"].length >= 1
  end

  # Test 2: GET /api/items?search=salade retourne les items correspondants
  test "search retourne uniquement les items dont le nom contient le terme" do
    get "/api/items", params: { search: "Salade" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1
    assert_match(/salade/i, json["data"].first["name"])
  end

  # Test 3: GET /api/items?sort=asc retourne les items triés par prix croissant
  test "sort asc retourne les items triés par prix croissant" do
    get "/api/items", params: { sort: "asc" }

    assert_response :ok
    json = JSON.parse(response.body)
    prices = json["data"].map { |i| i["price"] }
    assert_equal prices, prices.sort
  end

  # Test 4: GET /api/items?sort=desc retourne les items triés par prix décroissant
  test "sort desc retourne les items triés par prix décroissant" do
    get "/api/items", params: { sort: "desc" }

    assert_response :ok
    json = JSON.parse(response.body)
    prices = json["data"].map { |i| i["price"] }
    assert_equal prices, prices.sort.reverse
  end

  # Test 5: GET /api/items?price_min=10&price_max=16 retourne les items dans la fourchette
  test "filter par prix retourne uniquement les items dans la fourchette" do
    get "/api/items", params: { price_min: 10, price_max: 16 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    prices = json["data"].map { |i| i["price"] }
    assert prices.all? { |p| p >= 10 }, "Un prix est inférieur à 10"
    assert prices.all? { |p| p <= 16 }, "Un prix est supérieur à 16"
  end

  # Test 6: Un item dont la catégorie a une availability active apparaît dans le menu
  test "item avec catégorie disponible apparaît dans le menu public" do
    delete "/users/sign_out", as: :json

    get "/api/items"

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    # La catégorie entrees a une availability active (fixture category_one_availability)
    ids = json["data"].map { |i| i["id"] }
    assert_includes ids, @item["id"], "L'item dans une catégorie disponible devrait apparaître"
  end

  # Test 7: Un item dont la catégorie n'a aucune availability active est exclu du menu
  test "item avec catégorie indisponible est exclu du menu public" do
    category_desserts = categories(:desserts)

    # Créer un item dans la catégorie desserts (sans availability de catégorie)
    post "/api/items", params: {
      item: {
        name: "Gâteau chocolat", description: "Fondant",
        price: 12.99, category_id: category_desserts.id,
        image: fixture_file_upload("test.jpg", "image/jpeg")
      }
    }
    item_dessert = JSON.parse(response.body)["data"]

    # Ajouter une availability active sur l'item lui-même
    Availability.create!(
      available_type: "Item",
      available_id: item_dessert["id"],
      start_at: Time.current.beginning_of_minute,
      end_at: nil
    )

    # Vérifier que la catégorie desserts n'a aucune availability active
    now = Time.current
    assert_equal 0, Availability.where(available_type: "Category", available_id: category_desserts.id)
                                .where("start_at <= ? AND (end_at IS NULL OR end_at > ?)", now, now).count

    delete "/users/sign_out", as: :json

    get "/api/items"

    assert_response :ok
    json = JSON.parse(response.body)
    ids = json["data"].map { |i| i["id"] }
    assert_not_includes ids, item_dessert["id"], "L'item dans une catégorie sans availability ne devrait pas apparaître"
  end
end
