require "test_helper"

class TableSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)

    # Connexion admin
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    # Créer des tables pour les tests
    post "/api/tables", params: {
      table: { number: 1, nb_seats: 2 }
    }, as: :json
    @table1 = JSON.parse(response.body)["data"]

    post "/api/tables", params: {
      table: { number: 2, nb_seats: 6 }
    }, as: :json
    @table2 = JSON.parse(response.body)["data"]

    post "/api/tables", params: {
      table: { number: 3, nb_seats: 10 }
    }, as: :json
    @table3 = JSON.parse(response.body)["data"]
  end

  # ══════════════════════════════════════════
  # USER - Tests d'autorisation positifs
  # ══════════════════════════════════════════

  # Test 1: Un admin peut créer une table
  test "admin peut créer une table" do
    post "/api/tables", params: {
      table: { number: 50, nb_seats: 4 }
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert json["success"]
  end

  # Test 2: Un admin peut modifier une table
  test "admin peut modifier une table" do
    patch "/api/tables/#{@table1['id']}", params: {
      table: { nb_seats: 8 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end

  # Test 3: Un admin peut supprimer une table
  test "admin peut supprimer une table" do
    delete "/api/tables/#{@table3['id']}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end

  # Test 4: Un utilisateur non connecté peut lire la liste des tables
  test "utilisateur non connecté peut lire la liste des tables" do
    delete "/users/sign_out", as: :json

    get "/api/tables", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end

  # ══════════════════════════════════════════
  # CREATE
  # ══════════════════════════════════════════

  # Test 5: POST /api/tables avec tous les champs valides
  test "create avec champs valides retourne 201 et success true" do
    post "/api/tables", params: {
      table: { number: 10, nb_seats: 8 }
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 10, json["data"]["number"]
    assert_equal 8, json["data"]["capacity"]
    assert_equal "available", json["data"]["status"]
    assert_not_nil json["data"]["qr_token"]
  end

  # Test 6: POST /api/tables avec nb_seats minimum (1)
  test "create avec nb_seats minimum (1) retourne 201" do
    post "/api/tables", params: {
      table: { number: 11, nb_seats: 1 }
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 1, json["data"]["capacity"]
  end

  # Test 7: POST /api/tables avec nb_seats maximum (20)
  test "create avec nb_seats maximum (20) retourne 201" do
    post "/api/tables", params: {
      table: { number: 12, nb_seats: 20 }
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 20, json["data"]["capacity"]
  end

  # Test 8: POST /api/tables avec numéro maximum (999)
  test "create avec numéro maximum (999) retourne 201" do
    post "/api/tables", params: {
      table: { number: 999, nb_seats: 4 }
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 999, json["data"]["number"]
  end

  # Test 9: Un qr_token unique est généré automatiquement
  test "create génère un qr_token unique pour chaque table" do
    post "/api/tables", params: {
      table: { number: 14, nb_seats: 4 }
    }, as: :json
    token1 = JSON.parse(response.body)["data"]["qr_token"]

    post "/api/tables", params: {
      table: { number: 15, nb_seats: 4 }
    }, as: :json
    token2 = JSON.parse(response.body)["data"]["qr_token"]

    assert_not_nil token1
    assert_not_nil token2
    assert_not_equal token1, token2
  end

  # ══════════════════════════════════════════
  # READ
  # ══════════════════════════════════════════

  # Test 10: GET /api/tables/:qr_token retourne la table
  test "read par qr_token retourne la table avec success true" do
    get "/api/tables/#{@table1['qr_token']}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal @table1["id"], json["data"]["id"]
    assert_equal @table1["number"], json["data"]["number"]
    assert_equal @table1["capacity"], json["data"]["capacity"]
  end

  # Test 11: Read retourne toutes les propriétés attendues
  test "read retourne toutes les propriétés attendues" do
    get "/api/tables/#{@table2['qr_token']}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    data = json["data"]
    assert_not_nil data["id"]
    assert_not_nil data["number"]
    assert_not_nil data["capacity"]
    assert_not_nil data["status"]
    assert_not_nil data["qr_token"]
    assert_includes %w[available occupied], data["status"]
  end

  # ══════════════════════════════════════════
  # UPDATE
  # ══════════════════════════════════════════

  # Test 12: PATCH /api/tables/:id modifie le nombre de places
  test "update modifie le nombre de places" do
    patch "/api/tables/#{@table1['id']}", params: {
      table: { nb_seats: 10 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 10, json["data"]["capacity"]
  end

  # Test 13: PATCH /api/tables/:id modifie le numéro de table
  test "update modifie le numéro de table" do
    patch "/api/tables/#{@table1['id']}", params: {
      table: { number: 50 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 50, json["data"]["number"]
  end

  # Test 14: PATCH /api/tables/:id modifie numéro et places en même temps
  test "update modifie numéro et nb_seats en même temps" do
    patch "/api/tables/#{@table1['id']}", params: {
      table: { number: 60, nb_seats: 12 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 60, json["data"]["number"]
    assert_equal 12, json["data"]["capacity"]
  end

  # ══════════════════════════════════════════
  # DELETE
  # ══════════════════════════════════════════

  # Test 15: DELETE /api/tables/:id soft-delete la table
  test "delete soft-delete la table avec status 200" do
    delete "/api/tables/#{@table1['id']}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    # Vérifier que deleted_at est rempli en DB
    table = Table.unscoped.find(@table1["id"])
    assert_not_nil table.deleted_at
  end

  # Test 16: La table soft-deleted n'apparaît plus dans la liste
  test "table soft-deleted n'apparaît plus dans GET /api/tables" do
    delete "/api/tables/#{@table1['id']}", as: :json
    assert_response :ok

    get "/api/tables", as: :json
    json = JSON.parse(response.body)
    ids = json["data"].map { |t| t["id"] }
    assert_not_includes ids, @table1["id"]
  end

  # ══════════════════════════════════════════
  # LIST
  # ══════════════════════════════════════════

  # Test 17: GET /api/tables retourne toutes les tables
  test "list retourne toutes les tables avec success true et status 200" do
    get "/api/tables", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
    assert json["data"].length >= 3
  end

  # Test 18: Chaque table dans la liste contient les bonnes propriétés
  test "list retourne les propriétés attendues pour chaque table" do
    get "/api/tables", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    table = json["data"].find { |t| t["id"] == @table1["id"] }
    assert_not_nil table
    assert_equal 1, table["number"]
    assert_equal 2, table["capacity"]
    assert_includes %w[available occupied], table["status"]
    assert_not_nil table["qr_token"]
  end

  # Test 19: Les tables sont triées par numéro par défaut
  test "list retourne les tables triées par numéro par défaut" do
    get "/api/tables", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    numbers = json["data"].map { |t| t["number"] }
    assert_equal numbers, numbers.sort
  end

  # ══════════════════════════════════════════
  # SEARCH
  # ══════════════════════════════════════════

  # Test 20: GET /api/tables?search=2 retourne uniquement la table numéro 2
  test "search par numéro retourne la table correspondante" do
    get "/api/tables", params: { search: "2" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1
    json["data"].each do |table|
      assert_equal 2, table["number"]
    end
  end

  # Test 21: Search avec un numéro inexistant retourne une liste vide
  test "search avec numéro inexistant retourne liste vide" do
    get "/api/tables", params: { search: "888" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  # Test 22: Search sans paramètre retourne toutes les tables
  test "search sans paramètre retourne toutes les tables" do
    get "/api/tables", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 3
  end

  # ══════════════════════════════════════════
  # SORT
  # ══════════════════════════════════════════

  # Test 23: GET /api/tables?sort=asc retourne les tables triées par capacité croissante
  test "sort asc retourne les tables triées par capacité croissante" do
    get "/api/tables", params: { sort: "asc" }

    assert_response :ok
    json = JSON.parse(response.body)
    capacities = json["data"].map { |t| t["capacity"] }
    assert_equal capacities, capacities.sort
  end

  # Test 24: GET /api/tables?sort=desc retourne les tables triées par capacité décroissante
  test "sort desc retourne les tables triées par capacité décroissante" do
    get "/api/tables", params: { sort: "desc" }

    assert_response :ok
    json = JSON.parse(response.body)
    capacities = json["data"].map { |t| t["capacity"] }
    assert_equal capacities, capacities.sort.reverse
  end

  # Test 25: Sans sort, tri par numéro par défaut
  test "sans paramètre sort, tri par numéro par défaut" do
    get "/api/tables", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    numbers = json["data"].map { |t| t["number"] }
    assert_equal numbers, numbers.sort
  end

  # ══════════════════════════════════════════
  # FILTER
  # ══════════════════════════════════════════

  # Test 26: GET /api/tables?capacity_min=5 retourne les tables avec 5+ places
  test "filter capacity_min retourne les tables avec assez de places" do
    get "/api/tables", params: { capacity_min: 5 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    json["data"].each do |table|
      assert table["capacity"] >= 5, "Capacité #{table['capacity']} est inférieure à 5"
    end
  end

  # Test 27: GET /api/tables?capacity_max=4 retourne les tables avec 4 places ou moins
  test "filter capacity_max retourne les tables avec places limitées" do
    get "/api/tables", params: { capacity_max: 4 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    json["data"].each do |table|
      assert table["capacity"] <= 4, "Capacité #{table['capacity']} est supérieure à 4"
    end
  end

  # Test 28: GET /api/tables?capacity_min=3&capacity_max=8 retourne les tables dans la fourchette
  test "filter par fourchette de capacité retourne les tables dans l'intervalle" do
    get "/api/tables", params: { capacity_min: 3, capacity_max: 8 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    json["data"].each do |table|
      assert table["capacity"] >= 3, "Capacité #{table['capacity']} est inférieure à 3"
      assert table["capacity"] <= 8, "Capacité #{table['capacity']} est supérieure à 8"
    end
    # Table 2 (6 places) devrait être incluse
    ids = json["data"].map { |t| t["id"] }
    assert_includes ids, @table2["id"]
  end

  # Test 29: Filter avec fourchette excluant tout retourne liste vide
  test "filter avec fourchette impossible retourne liste vide" do
    get "/api/tables", params: { capacity_min: 100, capacity_max: 200 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end
end
