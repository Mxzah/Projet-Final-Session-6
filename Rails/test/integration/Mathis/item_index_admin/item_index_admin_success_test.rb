require "test_helper"

class ItemIndexAdminSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @category_entrees = categories(:entrees)
    @category_plats = categories(:plats)
    @item_one = items(:item_one)       # Tartare, 24.99$, entrees
    @item_two = items(:item_two)       # Bruschetta, 14.50$, entrees
    @item_three = items(:item_three)   # Salade César, 16.99$, entrees

    # Attacher une image aux fixtures
    [@item_one, @item_two, @item_three].each do |item|
      item.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")), filename: "test.jpg", content_type: "image/jpeg")
    end

    # Créer des availabilities actives (start_at maintenant, pas de end_at)
    [@item_one, @item_two, @item_three].each do |item|
      Availability.create!(
        available_type: "Item",
        available_id:   item.id,
        start_at:       Time.current.beginning_of_minute,
        end_at:         nil
      )
    end

    # Créer un item puis l'archiver via soft_delete!
    @item_archived = Item.new(
      name: "Ancien Plat Archivé",
      description: "Ne devrait plus être au menu",
      price: 22.00,
      category: @category_plats
    )
    @item_archived.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")), filename: "test.jpg", content_type: "image/jpeg")
    @item_archived.save!
    @item_archived.soft_delete!

    # Vérifier en BD que l'item est bien archivé
    assert_not_nil Item.unscoped.find(@item_archived.id).deleted_at

    sign_in users(:admin_user)
  end

  # Test 1: admin=true retourne les items archivés (vérification API + BD)
  test "admin=true retourne les items archivés visibles en BD via unscoped" do
    # Vérifier en BD que l'item est invisible avec le default_scope
    assert_nil Item.find_by(id: @item_archived.id)
    # Mais visible avec unscoped
    archived_in_db = Item.unscoped.find(@item_archived.id)
    assert_not_nil archived_in_db.deleted_at

    get "/api/items", params: { admin: true }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    ids = json["data"].map { |i| i["id"] }
    assert_includes ids, @item_archived.id
  end

  # Test 2: admin=true avec search filtre par nom (vérifié en BD)
  test "admin=true avec search filtre par nom et correspond aux items en BD" do
    items_in_db = Item.where("name LIKE ?", "%Tartare%")
    assert items_in_db.count >= 1

    get "/api/items", params: { admin: true, search: "Tartare" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1

    json["data"].each do |item_data|
      item_in_db = Item.unscoped.find(item_data["id"])
      assert_match(/tartare/i, item_in_db.name)
    end
  end

  # Test 3: admin=true avec search retrouve un item archivé (vérifié en BD)
  test "admin=true avec search trouve l'item archivé et correspond à la BD" do
    get "/api/items", params: { admin: true, search: "Ancien Plat" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1

    ids = json["data"].map { |i| i["id"] }
    assert_includes ids, @item_archived.id

    item_in_db = Item.unscoped.find(@item_archived.id)
    assert_not_nil item_in_db.deleted_at
    assert_match(/Ancien Plat/i, item_in_db.name)
  end

  # Test 4: admin=true avec sort=asc trie par prix croissant (vérifié en BD)
  test "admin=true avec sort asc trie par prix croissant cohérent avec la BD" do
    get "/api/items", params: { admin: true, sort: "asc" }

    assert_response :ok
    json = JSON.parse(response.body)
    prices = json["data"].map { |i| i["price"] }
    assert_equal prices, prices.sort

    json["data"].each do |item_data|
      item_in_db = Item.unscoped.find(item_data["id"])
      assert_equal item_in_db.price.to_f, item_data["price"].to_f
    end
  end

  # Test 5: admin=true avec sort=desc trie par prix décroissant (vérifié en BD)
  test "admin=true avec sort desc trie par prix décroissant cohérent avec la BD" do
    get "/api/items", params: { admin: true, sort: "desc" }

    assert_response :ok
    json = JSON.parse(response.body)
    prices = json["data"].map { |i| i["price"] }
    assert_equal prices, prices.sort.reverse

    first_item = Item.unscoped.find(json["data"].first["id"])
    last_item = Item.unscoped.find(json["data"].last["id"])
    assert first_item.price >= last_item.price
  end

  # Test 6: admin=true avec price_min exclut les items moins chers (vérifié en BD)
  test "admin=true avec price_min exclut les items moins chers en BD" do
    get "/api/items", params: { admin: true, price_min: 16 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    json["data"].each do |item_data|
      item_in_db = Item.unscoped.find(item_data["id"])
      assert item_in_db.price >= 16, "Item #{item_in_db.name} a un prix de #{item_in_db.price}, devrait être >= 16"
    end

    ids = json["data"].map { |i| i["id"] }
    assert_not_includes ids, @item_two.id, "Bruschetta (14.50$) ne devrait pas apparaître avec price_min=16"
  end

  # Test 7: admin=true avec price_max exclut les items plus chers (vérifié en BD)
  test "admin=true avec price_max exclut les items plus chers en BD" do
    get "/api/items", params: { admin: true, price_max: 20 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    json["data"].each do |item_data|
      item_in_db = Item.unscoped.find(item_data["id"])
      assert item_in_db.price <= 20, "Item #{item_in_db.name} a un prix de #{item_in_db.price}, devrait être <= 20"
    end

    ids = json["data"].map { |i| i["id"] }
    assert_not_includes ids, @item_one.id, "Tartare (24.99$) ne devrait pas apparaître avec price_max=20"
  end

  # Test 8: admin=true avec price_min + price_max filtre la fourchette (vérifié en BD)
  test "admin=true avec price_min et price_max filtre la fourchette en BD" do
    get "/api/items", params: { admin: true, price_min: 15, price_max: 20 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    json["data"].each do |item_data|
      item_in_db = Item.unscoped.find(item_data["id"])
      assert item_in_db.price >= 15 && item_in_db.price <= 20,
        "Item #{item_in_db.name} (#{item_in_db.price}$) hors fourchette 15-20$"
    end

    ids = json["data"].map { |i| i["id"] }
    assert_not_includes ids, @item_two.id
    assert_not_includes ids, @item_one.id
    assert_includes ids, @item_three.id
  end

  # Test 9: Combinaison search + sort + price (vérifié en BD)
  test "admin=true avec search sort et price combinés cohérent avec BD" do
    get "/api/items", params: { admin: true, search: "Salade", sort: "asc", price_min: 1, price_max: 50 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1

    prices = json["data"].map { |i| i["price"] }
    assert_equal prices, prices.sort

    json["data"].each do |item_data|
      item_in_db = Item.unscoped.find(item_data["id"])
      assert_match(/salade/i, item_in_db.name)
      assert item_in_db.price >= 1 && item_in_db.price <= 50
    end
  end

  # Test 10: Search sans résultat (vérifié en BD)
  test "admin=true avec search sans résultat retourne tableau vide" do
    assert_equal 0, Item.unscoped.where("name LIKE ?", "%xyzzzz_inexistant%").count

    get "/api/items", params: { admin: true, search: "xyzzzz_inexistant" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  # Test 11: Sans admin=true, l'item archivé est invisible (vérifié en BD)
  test "sans admin=true l'item archivé est invisible malgré son existence en BD" do
    assert Item.unscoped.exists?(@item_archived.id)
    assert_not Item.exists?(@item_archived.id)

    get "/api/items"

    assert_response :ok
    json = JSON.parse(response.body)
    ids = json["data"].map { |i| i["id"] }
    assert_not_includes ids, @item_archived.id
  end

  # Test 12: admin=true retourne les items même si leur catégorie n'a pas d'availability active
  test "admin=true retourne un item dont la catégorie n'a aucune availability" do
    category_desserts = categories(:desserts)

    # Vérifier que la catégorie desserts n'a aucune availability
    assert_equal 0, Availability.where(available_type: "Category", available_id: category_desserts.id).count

    # Créer un item dans la catégorie desserts
    item_dessert = Item.new(
      name: "Crème brûlée",
      description: "Dessert classique",
      price: 9.99,
      category: category_desserts
    )
    item_dessert.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")), filename: "test.jpg", content_type: "image/jpeg")
    item_dessert.save!

    get "/api/items", params: { admin: true }

    assert_response :ok
    json = JSON.parse(response.body)
    ids = json["data"].map { |i| i["id"] }
    assert_includes ids, item_dessert.id, "En mode admin, l'item devrait apparaître même si sa catégorie n'a pas d'availability"
  end

  # Test 13: Sans admin=true, un item dans une catégorie sans availability est exclu
  test "sans admin=true l'item est exclu si sa catégorie n'a aucune availability" do
    category_desserts = categories(:desserts)

    # Créer un item dans la catégorie desserts avec sa propre availability active
    item_dessert = Item.new(
      name: "Tiramisu",
      description: "Dessert italien",
      price: 11.50,
      category: category_desserts
    )
    item_dessert.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")), filename: "test.jpg", content_type: "image/jpeg")
    item_dessert.save!

    Availability.create!(
      available_type: "Item",
      available_id:   item_dessert.id,
      start_at:       Time.current.beginning_of_minute,
      end_at:         nil
    )

    # L'item existe et a une availability active, mais sa catégorie n'en a pas
    assert Item.exists?(item_dessert.id)
    assert Availability.where(available_type: "Item", available_id: item_dessert.id)
                       .where("start_at <= ?", Time.current).exists?
    assert_equal 0, Availability.where(available_type: "Category", available_id: category_desserts.id)
                                .where("start_at <= ? AND (end_at IS NULL OR end_at > ?)", Time.current, Time.current).count

    get "/api/items"

    assert_response :ok
    json = JSON.parse(response.body)
    ids = json["data"].map { |i| i["id"] }
    assert_not_includes ids, item_dessert.id, "L'item ne devrait pas apparaître si sa catégorie n'a pas d'availability active"
  end
end
