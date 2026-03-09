# frozen_string_literal: true

require "test_helper"

class ItemsSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:entrees)
    @category2 = categories(:plats)
    @item_one = items(:item_one)       # Tartare, 24.99$
    @item_two = items(:item_two)       # Bruschetta, 14.50$
    @item_three = items(:item_three)   # Salade César, 16.99$
    @client = users(:valid_user)

    # Attacher une image aux fixtures
    [@item_one, @item_two, @item_three].each do |item|
      item.image.attach(
        io: File.open(Rails.root.join("test/fixtures/files/test.jpg")),
        filename: "test.jpg", content_type: "image/jpeg"
      )
    end

    sign_in users(:admin_user)
  end

  # ── Index (public) ──

  test "index retourne les items avec success true" do
    get "/api/items"

    assert_response :ok
    json = JSON.parse(response.body)

    assert json["success"]
    assert_instance_of Array, json["data"]
    assert json["data"].length >= 1
  end

  test "index avec search filtre par nom" do
    get "/api/items", params: { search: "Tartare" }

    assert_response :ok
    json = JSON.parse(response.body)

    assert json["success"]
    assert json["data"].length >= 1
    assert_match(/tartare/i, json["data"].first["name"])
  end

  test "index avec sort asc trie par prix croissant" do
    get "/api/items", params: { sort: "asc" }

    assert_response :ok
    json = JSON.parse(response.body)

    prices = json["data"].map { |i| i["price"] }
    assert_equal prices, prices.sort
  end

  test "index avec sort desc trie par prix décroissant" do
    get "/api/items", params: { sort: "desc" }

    assert_response :ok
    json = JSON.parse(response.body)

    prices = json["data"].map { |i| i["price"] }
    assert_equal prices, prices.sort.reverse
  end

  test "index avec price_min et price_max filtre la fourchette" do
    get "/api/items", params: { price_min: 10, price_max: 16 }

    assert_response :ok
    json = JSON.parse(response.body)

    assert json["success"]
    prices = json["data"].map { |i| i["price"] }
    assert prices.all? { |p| p >= 10 && p <= 16 }
  end

  test "index fonctionne sans authentification" do
    sign_out :user

    get "/api/items"

    assert_response :ok
    json = JSON.parse(response.body)

    assert json["success"]
    assert_instance_of Array, json["data"]
  end

  test "index avec catégorie disponible inclut l'item" do
    sign_out :user

    get "/api/items"

    assert_response :ok
    json = JSON.parse(response.body)

    # item_one a une availability active + catégorie entrees a une availability active
    ids = json["data"].map { |i| i["id"] }
    assert_includes ids, @item_one.id
  end

  # ── Index (admin) ──

  test "admin=true retourne les items archivés" do
    # Créer et archiver un item
    item = Item.new(name: "Archivé", description: "Test", price: 10.00, category: @category)
    item.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")),
                      filename: "test.jpg", content_type: "image/jpeg")
    item.save!
    item.soft_delete!

    # Validation de la cohérence de la base de données
    assert_not_nil Item.unscoped.find(item.id).deleted_at
    assert_nil Item.find_by(id: item.id)

    get "/api/items", params: { admin: true }

    assert_response :ok
    json = JSON.parse(response.body)

    assert json["success"]
    ids = json["data"].map { |i| i["id"] }
    assert_includes ids, item.id
  end

  test "admin=true avec search retrouve un item archivé" do
    item = Item.new(name: "Ancien Plat Archivé", description: "Test", price: 22.00, category: @category2)
    item.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")),
                      filename: "test.jpg", content_type: "image/jpeg")
    item.save!
    item.soft_delete!

    get "/api/items", params: { admin: true, search: "Ancien Plat" }

    assert_response :ok
    json = JSON.parse(response.body)

    assert json["success"]
    ids = json["data"].map { |i| i["id"] }
    assert_includes ids, item.id

    # Validation de la cohérence de la base de données
    assert_not_nil Item.unscoped.find(item.id).deleted_at
  end

  test "admin=true retourne un item dont la catégorie n'a aucune availability" do
    category_desserts = categories(:desserts)
    item = Item.new(name: "Crème brûlée", description: "Dessert", price: 9.99, category: category_desserts)
    item.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")),
                      filename: "test.jpg", content_type: "image/jpeg")
    item.save!

    get "/api/items", params: { admin: true }

    assert_response :ok
    json = JSON.parse(response.body)

    ids = json["data"].map { |i| i["id"] }
    assert_includes ids, item.id
  end

  # ── Show ──

  test "show retourne l'item avec toutes ses propriétés" do
    get "/api/items/#{@item_one.id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    assert json["success"]
    data = json["data"]
    assert_equal @item_one.name, data["name"]
    assert_equal @item_one.description, data["description"]
    assert_equal @item_one.price.to_f, data["price"]
    assert_equal @category.id, data["category_id"]
    assert_equal @category.name, data["category_name"]
    assert_not_nil data["image_url"]
    assert_not_nil data["created_at"]
  end

  test "show fonctionne avec un compte client" do
    sign_out :user
    sign_in @client

    get "/api/items/#{@item_one.id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    assert json["success"]
    assert_equal @item_one.id, json["data"]["id"]
  end

  # ── Create ──

  test "create avec champs valides et image JPG" do
    assert_difference "Item.count", 1 do
      post "/api/items", params: {
        item: {
          name: "Nouveau Item", description: "Description",
          price: 18.50, category_id: @category.id,
          image: fixture_file_upload("test.jpg", "image/jpeg")
        }
      }
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert json["success"]
    assert_equal "Nouveau Item", json["data"]["name"]
    assert_equal 18.50, json["data"]["price"]

    # Validation de la cohérence de la base de données
    created = Item.find_by(name: "Nouveau Item")
    assert_not_nil created
    assert_equal 18.50, created.price.to_f
    assert_equal @category.id, created.category_id
  end

  test "create sans description crée l'item" do
    assert_difference "Item.count", 1 do
      post "/api/items", params: {
        item: {
          name: "Sans Description", price: 11.00, category_id: @category.id,
          image: fixture_file_upload("test.jpg", "image/jpeg")
        }
      }
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert json["success"]

    # Validation de la cohérence de la base de données
    assert_not_nil Item.find_by(name: "Sans Description")
  end

  test "create avec image PNG crée l'item" do
    assert_difference "Item.count", 1 do
      post "/api/items", params: {
        item: {
          name: "Item PNG", description: "Test", price: 16.00,
          category_id: @category.id,
          image: fixture_file_upload("test.png", "image/png")
        }
      }
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert json["success"]
    assert_not_nil json["data"]["image_url"]
  end

  # ── Update ──

  test "update modifie le nom, la description et le prix" do
    patch "/api/items/#{@item_one.id}", params: {
      item: { name: "Tartare Modifié", description: "Nouvelle desc", price: 29.99 }
    }, as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert json["success"]
    assert_equal "Tartare Modifié", json["data"]["name"]
    assert_equal "Nouvelle desc", json["data"]["description"]
    assert_equal 29.99, json["data"]["price"]

    # Validation de la cohérence de la base de données
    @item_one.reload
    assert_equal "Tartare Modifié", @item_one.name
    assert_equal 29.99, @item_one.price.to_f
  end

  test "update change la catégorie" do
    patch "/api/items/#{@item_one.id}", params: {
      item: { category_id: @category2.id }
    }, as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert json["success"]
    assert_equal @category2.id, json["data"]["category_id"]

    # Validation de la cohérence de la base de données
    @item_one.reload
    assert_equal @category2.id, @item_one.category_id
  end

  test "update change l'image" do
    patch "/api/items/#{@item_one.id}", params: {
      item: { image: fixture_file_upload("test.png", "image/png") }
    }
    assert_response :ok

    json = JSON.parse(response.body)

    assert json["success"]
    assert_not_nil json["data"]["image_url"]
  end

  # ── Destroy (soft delete) ──

  test "destroy soft-delete l'item" do
    delete "/api/items/#{@item_one.id}", as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert json["success"]

    # Validation de la cohérence de la base de données
    item = Item.unscoped.find(@item_one.id)
    assert_not_nil item.deleted_at
    assert_nil Item.find_by(id: @item_one.id)
  end

  test "item soft-deleted n'apparaît plus dans index public" do
    delete "/api/items/#{@item_one.id}", as: :json
    assert_response :ok

    sign_out :user

    get "/api/items", as: :json
    json = JSON.parse(response.body)

    ids = json["data"].map { |i| i["id"] }
    assert_not_includes ids, @item_one.id
  end

  # ── Hard destroy ──

  test "hard_destroy supprime définitivement un item sans commandes ni combos" do
    # item_two n'a pas de order_lines ni de combo_items dans les fixtures
    assert_difference "Item.unscoped.count", -1 do
      delete "/api/items/#{@item_two.id}/hard", as: :json
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert json["success"]

    # Validation de la cohérence de la base de données
    assert_nil Item.unscoped.find_by(id: @item_two.id)
  end

  # ── Restore ──

  test "restore désarchive un item soft-deleted" do
    @item_one.soft_delete!

    # Validation que l'item est archivé
    assert_not_nil Item.unscoped.find(@item_one.id).deleted_at

    patch "/api/items/#{@item_one.id}/restore", as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert json["success"], "Expected success but got: #{json.inspect}"

    # Validation de la cohérence de la base de données
    item = Item.unscoped.find(@item_one.id)
    assert_nil item.deleted_at
  end

end
