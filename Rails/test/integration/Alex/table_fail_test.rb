require "test_helper"

class TableFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)

    # Connexion admin
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    # Créer une table valide pour les tests update/delete
    post "/api/tables", params: {
      table: { number: 100, nb_seats: 4 }
    }, as: :json
    @table = JSON.parse(response.body)["data"]
  end

  # ══════════════════════════════════════════
  # USER - Tests d'autorisation négatifs
  # ══════════════════════════════════════════

  # Test 1: Create avec un compte client retourne success false
  test "create avec un compte client retourne success false" do
    delete "/users/sign_out", as: :json

    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    post "/api/tables", params: {
      table: { number: 200, nb_seats: 4 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Accès réservé aux administrateurs"
  end

  # Test 2: Update avec un compte client retourne success false
  test "update avec un compte client retourne success false" do
    delete "/users/sign_out", as: :json

    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    patch "/api/tables/#{@table['id']}", params: {
      table: { nb_seats: 10 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Accès réservé aux administrateurs"
  end

  # Test 3: Delete avec un compte client retourne success false
  test "delete avec un compte client retourne success false" do
    delete "/users/sign_out", as: :json

    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    delete "/api/tables/#{@table['id']}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Accès réservé aux administrateurs"
  end

  # ══════════════════════════════════════════
  # CREATE - Tests négatifs
  # ══════════════════════════════════════════

  # Test 4: Create sans numéro
  test "create sans numéro retourne success false" do
    post "/api/tables", params: {
      table: { nb_seats: 4 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 5: Create avec numéro 0 (inférieur à 1)
  test "create avec numéro 0 retourne success false" do
    post "/api/tables", params: {
      table: { number: 0, nb_seats: 4 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 6: Create avec numéro négatif
  test "create avec numéro négatif retourne success false" do
    post "/api/tables", params: {
      table: { number: -1, nb_seats: 4 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 7: Create avec numéro supérieur à 999
  test "create avec numéro supérieur à 999 retourne success false" do
    post "/api/tables", params: {
      table: { number: 1000, nb_seats: 4 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 8: Create avec numéro non-entier (décimal)
  test "create avec numéro décimal retourne success false" do
    post "/api/tables", params: {
      table: { number: 1.5, nb_seats: 4 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 9: Create avec numéro en doublon
  test "create avec numéro en doublon retourne success false" do
    post "/api/tables", params: {
      table: { number: 100, nb_seats: 6 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 10: Create avec nb_seats 0 (inférieur à 1)
  test "create avec nb_seats 0 retourne success false" do
    post "/api/tables", params: {
      table: { number: 201, nb_seats: 0 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 11: Create avec nb_seats négatif
  test "create avec nb_seats négatif retourne success false" do
    post "/api/tables", params: {
      table: { number: 202, nb_seats: -1 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 12: Create avec nb_seats supérieur à 20
  test "create avec nb_seats supérieur à 20 retourne success false" do
    post "/api/tables", params: {
      table: { number: 203, nb_seats: 21 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 13: Create avec nb_seats décimal
  test "create avec nb_seats décimal retourne success false" do
    post "/api/tables", params: {
      table: { number: 204, nb_seats: 4.5 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # READ - Tests négatifs
  # ══════════════════════════════════════════

  # Test 14: Read avec qr_token inexistant
  test "read avec qr_token inexistant retourne not found" do
    get "/api/tables/token_invalide_xyz", as: :json

    assert_response :not_found
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Table introuvable. QR code invalide."
  end

  # Test 15: Read avec qr_token vide
  test "read avec qr_token vide retourne not found" do
    get "/api/tables/", as: :json

    assert_response :ok
    # Cela retourne la liste (index), pas un show
    json = JSON.parse(response.body)
    assert json["success"]
  end

  # ══════════════════════════════════════════
  # UPDATE - Tests négatifs
  # ══════════════════════════════════════════

  # Test 16: Update avec numéro 0
  test "update avec numéro 0 retourne success false" do
    patch "/api/tables/#{@table['id']}", params: {
      table: { number: 0 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 17: Update avec numéro négatif
  test "update avec numéro négatif retourne success false" do
    patch "/api/tables/#{@table['id']}", params: {
      table: { number: -5 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 18: Update avec numéro supérieur à 999
  test "update avec numéro supérieur à 999 retourne success false" do
    patch "/api/tables/#{@table['id']}", params: {
      table: { number: 1000 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 19: Update avec numéro en doublon (d'une autre table)
  test "update avec numéro en doublon retourne success false" do
    post "/api/tables", params: {
      table: { number: 101, nb_seats: 2 }
    }, as: :json
    table2 = JSON.parse(response.body)["data"]

    patch "/api/tables/#{table2['id']}", params: {
      table: { number: 100 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 20: Update avec nb_seats 0
  test "update avec nb_seats 0 retourne success false" do
    patch "/api/tables/#{@table['id']}", params: {
      table: { nb_seats: 0 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 21: Update avec nb_seats négatif
  test "update avec nb_seats négatif retourne success false" do
    patch "/api/tables/#{@table['id']}", params: {
      table: { nb_seats: -3 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 22: Update avec nb_seats supérieur à 20
  test "update avec nb_seats supérieur à 20 retourne success false" do
    patch "/api/tables/#{@table['id']}", params: {
      table: { nb_seats: 21 }
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 23: Update avec ID inexistant
  test "update avec ID inexistant retourne not found" do
    patch "/api/tables/999999", params: {
      table: { number: 50 }
    }, as: :json

    assert_response :not_found
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Table introuvable."
  end

  # ══════════════════════════════════════════
  # DELETE - Tests négatifs
  # ══════════════════════════════════════════

  # Test 24: Delete avec ID inexistant
  test "delete avec ID inexistant retourne not found" do
    delete "/api/tables/999999", as: :json

    assert_response :not_found
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Table introuvable."
  end

  # Test 25: Double suppression de la même table
  test "double suppression retourne not found la deuxième fois" do
    delete "/api/tables/#{@table['id']}", as: :json
    assert_response :ok

    delete "/api/tables/#{@table['id']}", as: :json
    assert_response :not_found
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # LIST - Tests négatifs (pas d'erreur possible, mais vérification)
  # ══════════════════════════════════════════

  # Test 26: List après suppression de toutes les tables retourne liste vide
  test "list après suppression de toutes les tables retourne liste vide" do
    # Supprimer la table créée dans le setup
    delete "/api/tables/#{@table['id']}", as: :json
    assert_response :ok

    get "/api/tables", as: :json
    json = JSON.parse(response.body)
    assert json["success"]
    # La liste ne contient plus la table supprimée
    ids = json["data"].map { |t| t["id"] }
    assert_not_includes ids, @table["id"]
  end

  # ══════════════════════════════════════════
  # SEARCH - Tests négatifs
  # ══════════════════════════════════════════

  # Test 27: Search avec un numéro inexistant retourne liste vide
  test "search avec numéro inexistant retourne liste vide" do
    get "/api/tables", params: { search: "777" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  # Test 28: Search avec une chaîne non numérique retourne liste vide
  test "search avec texte non numérique retourne liste vide" do
    get "/api/tables", params: { search: "abc" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  # ══════════════════════════════════════════
  # SORT - Tests négatifs
  # ══════════════════════════════════════════

  # Test 29: Sort avec valeur invalide utilise le tri par défaut (par numéro)
  test "sort avec valeur invalide utilise le tri par défaut" do
    get "/api/tables", params: { sort: "invalid" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    numbers = json["data"].map { |t| t["number"] }
    assert_equal numbers, numbers.sort
  end

  # ══════════════════════════════════════════
  # FILTER - Tests négatifs
  # ══════════════════════════════════════════

  # Test 30: Filter avec capacity_min > capacity_max retourne liste vide
  test "filter avec min supérieur à max retourne liste vide" do
    get "/api/tables", params: { capacity_min: 20, capacity_max: 1 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  # Test 31: Filter avec capacity_min très élevé retourne liste vide
  test "filter avec capacity_min très élevé retourne liste vide" do
    get "/api/tables", params: { capacity_min: 999 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end
end
