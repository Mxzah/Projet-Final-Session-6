require "test_helper"

class OrderLineFailTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    @category = categories(:entrees)

    # Connexion
    post "/users/sign_in", params: {
      user: { email: @user.email, password: "password123" }
    }, as: :json

    # Créer une table et un item
    @table = Table.create!(number: 99, nb_seats: 10)

    # Créer un item directement en DB (POST /api/items nécessite Administrator)
    item_record = Item.new(name: "Item Test Fail", price: 10.00, category: @category)
    item_record.image.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test.jpg")),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )
    item_record.save!
    @item = item_record.as_json

    # Créer une commande
    post "/api/orders", params: {
      order: { nb_people: 2, table_id: @table.id }
    }, as: :json
    @order = JSON.parse(response.body)["data"].first
  end

  # ══════════════════════════════════════════
  # NON-AUTHENTIFIÉ
  # ══════════════════════════════════════════

  # Test 1: Index sans être connecté retourne success false
  test "index sans authentification retourne success false" do
    delete "/users/sign_out", as: :json

    get "/api/orders/#{@order['id']}/order_lines", as: :json

    # Code HTTP
    assert_response :ok

    # Format JSON valide
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 2: Create sans être connecté retourne success false
  test "create sans authentification retourne success false" do
    delete "/users/sign_out", as: :json

    post "/api/orders/#{@order['id']}/order_lines", params: {
      order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item["id"] }
    }, as: :json

    # Code HTTP
    assert_response :ok

    # Format JSON valide
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # ══════════════════════════════════════════
  # ORDER NOT FOUND - Tests négatifs
  # ══════════════════════════════════════════

  # Test 3: Index avec order_id inexistant retourne success false
  test "index avec order_id inexistant retourne success false" do
    get "/api/orders/999999/order_lines", as: :json

    # Code HTTP
    assert_response :ok

    # Format JSON valide
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_instance_of Array, json["errors"]
    assert json["errors"].any?

    # Contenu du format JSON
    assert_equal [], json["data"]
  end

  # Test 4: Index avec commande appartenant à un autre client retourne success false
  test "index avec commande d'un autre client retourne success false" do
    # Créer un autre client avec sa propre commande
    other_user = Client.create!(
      email: "other2@test.ca",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Other", last_name: "User", status: "active"
    )
    other_table = Table.create!(number: 98, nb_seats: 4)
    other_order = Order.create!(nb_people: 1, table: other_table, client: other_user)

    get "/api/orders/#{other_order.id}/order_lines", as: :json

    # Code HTTP
    assert_response :ok

    # Format JSON valide
    json = JSON.parse(response.body)
    assert_not json["success"]

    # Contenu du format JSON: aucune donnée
    assert_equal [], json["data"]
  end

  # Test 5: Create avec order_id inexistant retourne success false
  test "create avec order_id inexistant retourne success false" do
    post "/api/orders/999999/order_lines", params: {
      order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item["id"] }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_equal [], json["data"]
  end

  # ══════════════════════════════════════════
  # QUANTITY invalide
  # ══════════════════════════════════════════

  # Test 6: Create sans quantity retourne success false
  test "create sans quantity retourne success false" do
    post "/api/orders/#{@order['id']}/order_lines", params: {
      order_line: { orderable_type: "Item", orderable_id: @item["id"] }
    }, as: :json

    # Code HTTP
    assert_response :ok

    # Format JSON valide
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?

    # Contenu du format JSON
    assert_equal [], json["data"]
  end

  # Test 7: Create avec quantity = 0 retourne success false
  test "create avec quantity = 0 retourne success false" do
    post "/api/orders/#{@order['id']}/order_lines", params: {
      order_line: { quantity: 0, orderable_type: "Item", orderable_id: @item["id"] }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 8: Create avec quantity > 50 retourne success false
  test "create avec quantity supérieure à 50 retourne success false" do
    post "/api/orders/#{@order['id']}/order_lines", params: {
      order_line: { quantity: 51, orderable_type: "Item", orderable_id: @item["id"] }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # ORDERABLE invalide
  # ══════════════════════════════════════════

  # Test 9: Create avec orderable_type invalide retourne success false
  # On utilise "User" (classe valide mais pas dans %w[Item Combo])
  test "create avec orderable_type invalide retourne success false" do
    post "/api/orders/#{@order['id']}/order_lines", params: {
      order_line: { quantity: 1, orderable_type: "User", orderable_id: @item["id"] }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 10: Create avec orderable_id inexistant retourne success false
  test "create avec orderable_id inexistant retourne success false" do
    post "/api/orders/#{@order['id']}/order_lines", params: {
      order_line: { quantity: 1, orderable_type: "Item", orderable_id: 999999 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # NOTE invalide
  # ══════════════════════════════════════════

  # Test 11: Create avec note dépassant 255 caractères retourne success false
  test "create avec note dépassant 255 caractères retourne success false" do
    post "/api/orders/#{@order['id']}/order_lines", params: {
      order_line: {
        quantity: 1,
        orderable_type: "Item",
        orderable_id: @item["id"],
        note: "A" * 256
      }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # COHÉRENCE BASE DE DONNÉES
  # ══════════════════════════════════════════

  # Test 12: Create invalide ne sauvegarde rien en DB
  test "create invalide ne sauvegarde rien en base de données" do
    assert_no_difference "OrderLine.count" do
      post "/api/orders/#{@order['id']}/order_lines", params: {
        order_line: { quantity: 0, orderable_type: "Item", orderable_id: @item["id"] }
      }, as: :json
    end
  end
end
