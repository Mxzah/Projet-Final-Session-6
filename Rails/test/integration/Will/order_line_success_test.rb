require "test_helper"

class OrderLineSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    @category = categories(:entrees)

    # Connexion
    post "/users/sign_in", params: {
      user: { email: @user.email, password: "password123" }
    }, as: :json

    # Créer une table directement en DB
    @table = Table.create!(number: 99, nb_seats: 10)

    # Créer un item directement en DB (POST /api/items nécessite Administrator)
    item_record = Item.new(name: "Salade Test", description: "Une salade pour les tests", price: 12.50, category: @category)
    item_record.image.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test.jpg")),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )
    item_record.save!
    @item = item_record.as_json

    # Rendre l'item disponible (bypass validation start_at_not_in_past)
    av = Availability.new(available_type: "Item", available_id: item_record.id,
                          start_at: 1.hour.ago, end_at: 1.day.from_now)
    av.save(validate: false)

    # Créer une commande
    post "/api/orders", params: {
      order: { nb_people: 2, table_id: @table.id }
    }, as: :json
    @order = JSON.parse(response.body)["data"].first
  end

  # ══════════════════════════════════════════
  # INDEX - GET /api/orders/:order_id/order_lines
  # ══════════════════════════════════════════

  # Test 1: Index retourne 200 et success true
  test "index retourne status 200 et success true" do
    get "/api/orders/#{@order['id']}/order_lines", as: :json

    # Code HTTP
    assert_response :ok

    # Format JSON valide
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
    assert_instance_of Array, json["errors"]
  end

  # Test 2: Index retourne tableau vide si aucune ligne
  test "index retourne tableau vide si aucune ligne de commande" do
    get "/api/orders/#{@order['id']}/order_lines", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # Contenu du format JSON
    assert json["success"]
    assert_equal [], json["data"]
  end

  # Test 3: Index retourne les lignes existantes
  test "index retourne les lignes de commande après création" do
    # Créer une ligne de commande
    post "/api/orders/#{@order['id']}/order_lines", params: {
      order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item["id"] }
    }, as: :json

    get "/api/orders/#{@order['id']}/order_lines", as: :json

    json = JSON.parse(response.body)
    assert json["success"]

    # Contenu: 1 ligne
    assert_equal 1, json["data"].length
    assert_equal @item["id"], json["data"].first["orderable_id"]
  end

  # ══════════════════════════════════════════
  # CREATE - POST /api/orders/:order_id/order_lines
  # ══════════════════════════════════════════

  # Test 4: Create avec champs valides retourne success true
  test "create avec quantity et orderable valides retourne success true" do
    post "/api/orders/#{@order['id']}/order_lines", params: {
      order_line: { quantity: 2, orderable_type: "Item", orderable_id: @item["id"] }
    }, as: :json

    # Code HTTP
    assert_response :ok

    # Format JSON valide
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]

    # Contenu du format JSON
    assert_equal 2, json["data"].first["quantity"]
    assert_equal "Item", json["data"].first["orderable_type"]
    assert_equal @item["id"], json["data"].first["orderable_id"]
  end

  # Test 5: Create assigne automatiquement le status "sent"
  test "create assigne automatiquement le status sent" do
    post "/api/orders/#{@order['id']}/order_lines", params: {
      order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item["id"] }
    }, as: :json

    json = JSON.parse(response.body)

    # Contenu du format JSON
    assert_equal "sent", json["data"].first["status"]
  end

  # Test 6: Create assigne automatiquement unit_price depuis le prix de l'item
  test "create assigne unit_price automatiquement depuis le prix de l'item" do
    post "/api/orders/#{@order['id']}/order_lines", params: {
      order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item["id"] }
    }, as: :json

    json = JSON.parse(response.body)

    # Contenu du format JSON: prix == prix de l'item (12.50)
    assert_equal 12.50, json["data"].first["unit_price"]

    # Validation de la cohérence de la base de données
    line = OrderLine.find(json["data"].first["id"])
    assert_equal 12.50, line.unit_price.to_f
  end

  # Test 7: Create avec une note valide
  test "create avec une note valide crée la ligne avec la note" do
    post "/api/orders/#{@order['id']}/order_lines", params: {
      order_line: {
        quantity: 1,
        orderable_type: "Item",
        orderable_id: @item["id"],
        note: "Sans sel"
      }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    # Contenu du format JSON
    assert_equal "Sans sel", json["data"].first["note"]
  end

  # Test 8: Create retourne le nom de l'item dans orderable_name
  test "create retourne le nom de l'item dans orderable_name" do
    post "/api/orders/#{@order['id']}/order_lines", params: {
      order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item["id"] }
    }, as: :json

    json = JSON.parse(response.body)

    # Contenu du format JSON
    assert_equal "Salade Test", json["data"].first["orderable_name"]
  end

  # Test 9: Create sauvegarde la ligne en base de données
  test "create sauvegarde la ligne de commande en DB" do
    assert_difference "OrderLine.count", 1 do
      post "/api/orders/#{@order['id']}/order_lines", params: {
        order_line: { quantity: 3, orderable_type: "Item", orderable_id: @item["id"] }
      }, as: :json
    end

    # Validation de la cohérence de la base de données
    line = OrderLine.last
    assert_equal 3, line.quantity
    assert_equal "sent", line.status
    assert_equal @order["id"], line.order_id
  end
end
