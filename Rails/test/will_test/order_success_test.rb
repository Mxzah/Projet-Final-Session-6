require "test_helper"

class OrderSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)

    # Connexion
    post "/users/sign_in", params: {
      user: { email: @user.email, password: "password123" }
    }, as: :json

    # Créer une table directement en DB (pas besoin d'image pour Table)
    @table = Table.create!(number: 99, nb_seats: 10)
  end

  # ══════════════════════════════════════════
  # INDEX - GET /api/orders
  # ══════════════════════════════════════════

  # Test 1: Index retourne 200 et success true quand aucune commande
  test "index retourne status 200 et success true" do
    get "/api/orders", as: :json

    # Code HTTP
    assert_response :ok

    # Format JSON valide
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
    assert_instance_of Array, json["errors"]
  end

  # Test 2: Index retourne un tableau vide si aucune commande
  test "index retourne tableau vide si aucune commande" do
    get "/api/orders", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # Contenu du format JSON
    assert json["success"]
    assert_equal [], json["data"]
  end

  # Test 3: Index retourne les commandes du client connecté
  test "index retourne les commandes appartenant au client connecté" do
    # Créer une commande
    post "/api/orders", params: {
      order: { nb_people: 2, table_id: @table.id }
    }, as: :json

    get "/api/orders", as: :json

    json = JSON.parse(response.body)
    assert json["success"]

    # Contenu: au moins 1 commande
    assert json["data"].length >= 1

    # Validation: toutes les commandes appartiennent au bon client
    json["data"].each do |order|
      assert_equal @user.id, order["client_id"]
    end
  end

  # Test 4: Index retourne les bons champs dans chaque commande
  test "index retourne les champs attendus dans chaque commande" do
    post "/api/orders", params: {
      order: { nb_people: 3, table_id: @table.id, note: "Test note" }
    }, as: :json

    get "/api/orders", as: :json

    json = JSON.parse(response.body)
    order = json["data"].first

    # Contenu du format JSON
    assert order.key?("id")
    assert order.key?("nb_people")
    assert order.key?("note")
    assert order.key?("table_id")
    assert order.key?("table_number")
    assert order.key?("client_id")
    assert order.key?("order_lines")
    assert order.key?("created_at")
    assert order.key?("total")
  end

  # ══════════════════════════════════════════
  # SHOW - GET /api/orders/:id
  # ══════════════════════════════════════════

  # Test 5: Show retourne 200 et success true
  test "show retourne status 200 et success true" do
    post "/api/orders", params: {
      order: { nb_people: 2, table_id: @table.id }
    }, as: :json
    order_id = JSON.parse(response.body)["data"].first["id"]

    get "/api/orders/#{order_id}", as: :json

    # Code HTTP
    assert_response :ok

    # Format JSON valide
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
  end

  # Test 6: Show retourne la bonne commande avec ses données
  test "show retourne les données correctes de la commande" do
    post "/api/orders", params: {
      order: { nb_people: 4, table_id: @table.id, note: "Sans gluten" }
    }, as: :json
    order_id = JSON.parse(response.body)["data"].first["id"]

    get "/api/orders/#{order_id}", as: :json

    json = JSON.parse(response.body)
    order = json["data"].first

    # Contenu du format JSON
    assert_equal order_id, order["id"]
    assert_equal 4, order["nb_people"]
    assert_equal "Sans gluten", order["note"]
    assert_equal @table.id, order["table_id"]
    assert_equal @table.number, order["table_number"]
    assert_equal @user.id, order["client_id"]
  end

  # ══════════════════════════════════════════
  # CREATE - POST /api/orders
  # ══════════════════════════════════════════

  # Test 7: Create avec champs valides retourne success true
  test "create avec nb_people et table_id valides retourne success true" do
    post "/api/orders", params: {
      order: { nb_people: 2, table_id: @table.id }
    }, as: :json

    # Code HTTP
    assert_response :ok

    # Format JSON valide
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]

    # Contenu du format JSON
    assert_equal 2, json["data"].first["nb_people"]
    assert_equal @table.id, json["data"].first["table_id"]
  end


  # Test 9: Create avec une note valide
  test "create avec une note valide crée la commande avec la note" do
    post "/api/orders", params: {
      order: { nb_people: 2, table_id: @table.id, note: "Allergie aux noix" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    # Contenu du format JSON
    assert_equal "Allergie aux noix", json["data"].first["note"]
  end

  # Test 10: Create sauvegarde la commande en DB
  test "create sauvegarde la commande en base de données" do
    assert_difference "Order.count", 1 do
      post "/api/orders", params: {
        order: { nb_people: 2, table_id: @table.id }
      }, as: :json
    end
  end

  # ══════════════════════════════════════════
  # CLOSE OPEN - POST /api/orders/close_open
  # ══════════════════════════════════════════

  # Test 11: Close_open ferme toutes les commandes ouvertes
  test "close_open ferme toutes les commandes ouvertes du client" do
    # Créer une commande ouverte
    post "/api/orders", params: {
      order: { nb_people: 2, table_id: @table.id }
    }, as: :json
    order_id = JSON.parse(response.body)["data"].first["id"]

    post "/api/orders/close_open", as: :json

    # Code HTTP
    assert_response :ok

    # Format JSON valide
    json = JSON.parse(response.body)
    assert json["success"]

    # Validation de la cohérence de la base de données
    order = Order.unscoped.find(order_id)   #cherche totue sans filtre 
    assert_not_nil order.ended_at
  end

  # Test 12: Close_open retourne success true même si aucune commande ouverte
  test "close_open retourne success true si aucune commande ouverte" do
    post "/api/orders/close_open", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end
end
