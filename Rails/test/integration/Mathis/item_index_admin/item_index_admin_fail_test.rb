require "test_helper"

class ItemIndexAdminFailTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:entrees)

    # Créer un item et l'archiver directement en BD
    @item_archived = Item.new(
      name: "Item Secret Archivé",
      description: "Test",
      price: 15.00,
      category: @category
    )
    @item_archived.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")), filename: "test.jpg", content_type: "image/jpeg")
    @item_archived.save!
    @item_archived.soft_delete!

    # Vérifier en BD que l'item est bien archivé
    assert_not_nil Item.unscoped.find(@item_archived.id).deleted_at
    assert_nil Item.find_by(id: @item_archived.id)
  end

  # Test 1: Un client ne voit pas les items archivés même avec admin=true
  test "client avec admin=true ne voit pas les items archivés" do
    sign_in users(:valid_user)

    # L'item archivé existe en BD via unscoped
    assert Item.unscoped.exists?(@item_archived.id)

    get "/api/items", params: { admin: true }

    assert_response :ok
    json = JSON.parse(response.body)
    ids = json["data"].map { |i| i["id"] }
    assert_not_includes ids, @item_archived.id
  end

  # Test 2: Un serveur ne voit pas les items archivés même avec admin=true
  test "serveur avec admin=true ne voit pas les items archivés" do
    sign_in users(:waiter_user)

    assert Item.unscoped.exists?(@item_archived.id)

    get "/api/items", params: { admin: true }

    assert_response :ok
    json = JSON.parse(response.body)
    ids = json["data"].map { |i| i["id"] }
    assert_not_includes ids, @item_archived.id
  end

  # Test 3: Un utilisateur non connecté ne voit pas les items archivés
  test "utilisateur non connecté avec admin=true ne voit pas les items archivés" do
    assert Item.unscoped.exists?(@item_archived.id)

    get "/api/items", params: { admin: true }

    assert_response :ok
    json = JSON.parse(response.body)
    ids = json["data"].map { |i| i["id"] }
    assert_not_includes ids, @item_archived.id
  end

  # Test 4: price_min très élevé ne retourne aucun item (vérifié en BD)
  test "admin=true avec price_min très élevé retourne un tableau vide" do
    sign_in users(:admin_user)

    # Vérifier en BD qu'aucun item n'a un prix >= 99999
    assert_equal 0, Item.unscoped.where("price >= ?", 99999).count

    get "/api/items", params: { admin: true, price_min: 99999 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  # Test 5: price_max=0 ne retourne aucun item (vérifié en BD)
  test "admin=true avec price_max=0 retourne un tableau vide" do
    sign_in users(:admin_user)

    # Vérifier en BD qu'aucun item n'a un prix <= 0
    assert_equal 0, Item.unscoped.where("price <= ?", 0).count

    get "/api/items", params: { admin: true, price_max: 0 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end
end
