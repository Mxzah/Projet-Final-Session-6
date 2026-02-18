require "test_helper"

class OrderFailTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)

    # Connexion
    post "/users/sign_in", params: {
      user: { email: @user.email, password: "password123" }
    }, as: :json

    # Créer une table directement en DB
    @table = Table.create!(number: 99, nb_seats: 10)

    # Créer une commande ouverte pour les tests show/order_line
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
    # Déconnexion
    delete "/users/sign_out", as: :json

    get "/api/orders", as: :json

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

    post "/api/orders", params: {
      order: { nb_people: 2, table_id: @table.id }
    }, as: :json

    # Code HTTP
    assert_response :ok

    # Format JSON valide
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # ══════════════════════════════════════════
  # SHOW - Tests négatifs
  # ══════════════════════════════════════════

  # Test 3: Show avec ID inexistant retourne success false
  test "show avec ID inexistant retourne success false" do
    get "/api/orders/999999", as: :json

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

  # Test 4: Show avec commande appartenant à un autre client retourne success false
  test "show avec commande d'un autre client retourne success false" do
    # Créer un autre client avec sa propre commande
    other_user = Client.create!(
      email: "other@test.ca",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Other", last_name: "User", status: "active"
    )
    other_table = Table.create!(number: 98, nb_seats: 4)
    other_order = Order.create!(nb_people: 1, table: other_table, client: other_user)

    get "/api/orders/#{other_order.id}", as: :json

    # Code HTTP
    assert_response :ok

    # Format JSON valide
    json = JSON.parse(response.body)
    assert_not json["success"]

    # Contenu du format JSON: aucune donnée retournée
    assert_equal [], json["data"]
  end

  # ══════════════════════════════════════════
  # CREATE - Tests négatifs
  # ══════════════════════════════════════════

  # Test 5: Create sans nb_people retourne success false
  test "create sans nb_people retourne success false" do
    # Fermer la commande du setup pour éviter l'erreur "commande déjà ouverte"
    post "/api/orders/close_open", as: :json

    post "/api/orders", params: {
      order: { table_id: @table.id }
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

  # Test 6: Create avec nb_people = 0 retourne success false
  test "create avec nb_people = 0 retourne success false" do
    post "/api/orders/close_open", as: :json

    post "/api/orders", params: {
      order: { nb_people: 0, table_id: @table.id }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 7: Create avec nb_people > nb_seats de la table retourne success false
  test "create avec nb_people supérieur aux places de la table retourne success false" do
    post "/api/orders/close_open", as: :json

    # Table a 10 places, on met 11
    post "/api/orders", params: {
      order: { nb_people: 11, table_id: @table.id }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end



  # Test 9: Create sans table_id retourne success false
  test "create sans table_id retourne success false" do
    post "/api/orders/close_open", as: :json

    post "/api/orders", params: {
      order: { nb_people: 2 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 10: Create quand le client a déjà une commande ouverte retourne success false
  test "create avec commande déjà ouverte retourne success false" do
    # Le setup a déjà créé une commande ouverte, on essaie d'en créer une autre
    post "/api/orders", params: {
      order: { nb_people: 2, table_id: @table.id }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 11: Create avec note trop longue retourne success false
  test "create avec note dépassant 255 caractères retourne success false" do
    post "/api/orders/close_open", as: :json

    post "/api/orders", params: {
      order: { nb_people: 2, table_id: @table.id, note: "A" * 256 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 12: Create ne sauvegarde rien en DB si invalide
  test "create invalide ne sauvegarde rien en base de données" do
    post "/api/orders/close_open", as: :json

    assert_no_difference "Order.count" do
      post "/api/orders", params: {
        order: { nb_people: 0, table_id: @table.id }
      }, as: :json
    end
  end
end
