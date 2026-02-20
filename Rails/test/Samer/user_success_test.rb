require "test_helper"

class UserSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)
    @waiter = users(:waiter_user)
    @cook = users(:cook_user)
    @blocked = users(:blocked_user)

    # Connexion admin
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json
  end

  # ══════════════════════════════════════════
  # LIST
  # ══════════════════════════════════════════

  # Test 1: GET /api/users retourne tous les utilisateurs
  test "list retourne tous les utilisateurs avec success true et status 200" do
    get "/api/users"

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
    assert json["data"].length >= 5
  end

  # ══════════════════════════════════════════
  # READ
  # ══════════════════════════════════════════

  # Test 2: GET /api/users/:id retourne l'utilisateur avec toutes ses propriétés
  test "read retourne l'utilisateur avec toutes ses propriétés" do
    get "/api/users/#{@client.id}"

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    data = json["data"]
    assert_equal @client.email, data["email"]
    assert_equal @client.first_name, data["first_name"]
    assert_equal @client.last_name, data["last_name"]
    assert_equal "Client", data["type"]
    assert_equal "active", data["status"]
    assert_not_nil data["created_at"]
  end

  # ══════════════════════════════════════════
  # CREATE
  # ══════════════════════════════════════════

  # Test 3: POST /api/users crée un Client
  test "create un Client avec champs valides retourne 201" do
    post "/api/users", params: {
      user: { first_name: "Luc", last_name: "Bergeron", email: "luc@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Client" }
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Luc", json["data"]["first_name"]
    assert_equal "Client", json["data"]["type"]
  end

  # Test 4: POST /api/users crée un Administrator
  test "create un Administrator avec champs valides retourne 201" do
    post "/api/users", params: {
      user: { first_name: "Julie", last_name: "Martin", email: "julie@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Administrator" }
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Administrator", json["data"]["type"]
  end

  # Test 5: POST /api/users crée un Waiter
  test "create un Waiter avec champs valides retourne 201" do
    post "/api/users", params: {
      user: { first_name: "Paul", last_name: "Simard", email: "paul@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Waiter" }
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Waiter", json["data"]["type"]
  end

  # Test 6: POST /api/users crée un Cook
  test "create un Cook avec champs valides retourne 201" do
    post "/api/users", params: {
      user: { first_name: "Anne", last_name: "Bouchard", email: "anne@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Cook" }
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Cook", json["data"]["type"]
  end

  # ══════════════════════════════════════════
  # UPDATE
  # ══════════════════════════════════════════

  # Test 7: PATCH /api/users/:id modifie le nom
  test "update modifie le prénom et le nom" do
    patch "/api/users/#{@client.id}", params: {
      user: { first_name: "Jean-Pierre", last_name: "Tremblay-Roy" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Jean-Pierre", json["data"]["first_name"]
    assert_equal "Tremblay-Roy", json["data"]["last_name"]
  end

  # Test 8: PATCH /api/users/:id modifie l'email
  test "update modifie l'email" do
    patch "/api/users/#{@client.id}", params: {
      user: { email: "nouveau@restoqr.ca" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "nouveau@restoqr.ca", json["data"]["email"]
  end

  # Test 9: PATCH /api/users/:id modifie le type
  test "update modifie le type" do
    patch "/api/users/#{@client.id}", params: {
      user: { type: "Waiter" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Waiter", json["data"]["type"]
  end

  # Test 10: PATCH /api/users/:id modifie le statut
  test "update modifie le statut" do
    patch "/api/users/#{@client.id}", params: {
      user: { status: "blocked" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "blocked", json["data"]["status"]
  end

  # Test 11: PATCH /api/users/:id sans password ne change pas le mot de passe
  test "update sans password ne change pas le mot de passe" do
    patch "/api/users/#{@client.id}", params: {
      user: { first_name: "Nouveau" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Nouveau", json["data"]["first_name"]
  end

  # Test 12: PATCH /api/users/:id avec password vide ne change pas le mot de passe
  test "update avec password vide ne change pas le mot de passe" do
    patch "/api/users/#{@client.id}", params: {
      user: { first_name: "Autre", password: "", password_confirmation: "" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Autre", json["data"]["first_name"]
  end

  # ══════════════════════════════════════════
  # DELETE (soft delete)
  # ══════════════════════════════════════════

  # Test 13: DELETE /api/users/:id soft-delete l'utilisateur
  test "delete soft-delete l'utilisateur avec status 200" do
    delete "/api/users/#{@client.id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    # Vérifier que deleted_at est rempli en DB
    user = User.unscoped.find(@client.id)
    assert_not_nil user.deleted_at
  end

  # Test 14: L'utilisateur soft-deleted n'apparaît plus dans la liste
  test "utilisateur soft-deleted n'apparaît plus dans GET /api/users" do
    delete "/api/users/#{@client.id}", as: :json
    assert_response :ok

    get "/api/users"
    json = JSON.parse(response.body)
    ids = json["data"].map { |u| u["id"] }
    assert_not_includes ids, @client.id
  end

  # ══════════════════════════════════════════
  # SEARCH
  # ══════════════════════════════════════════

  # Test 15: Recherche par prénom
  test "search par prénom retourne les utilisateurs correspondants" do
    get "/api/users", params: { search: "Jean" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1
    json["data"].each do |user|
      assert(
        user["first_name"].downcase.include?("jean") ||
        user["last_name"].downcase.include?("jean") ||
        user["email"].downcase.include?("jean"),
        "L'utilisateur ne correspond pas à la recherche 'Jean'"
      )
    end
  end

  # Test 16: Recherche par email
  test "search par email retourne les utilisateurs correspondants" do
    get "/api/users", params: { search: "test@restoqr" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1
  end

  # ══════════════════════════════════════════
  # SORT
  # ══════════════════════════════════════════

  # Test 17: Tri ascendant par nom
  test "sort asc retourne les utilisateurs triés par nom croissant" do
    get "/api/users", params: { sort: "asc", sort_by: "last_name" }

    assert_response :ok
    json = JSON.parse(response.body)
    names = json["data"].map { |u| u["last_name"] }
    assert_equal names, names.sort
  end

  # Test 18: Tri descendant par nom
  test "sort desc retourne les utilisateurs triés par nom décroissant" do
    get "/api/users", params: { sort: "desc", sort_by: "last_name" }

    assert_response :ok
    json = JSON.parse(response.body)
    names = json["data"].map { |u| u["last_name"] }
    assert_equal names, names.sort.reverse
  end

  # ══════════════════════════════════════════
  # FILTER
  # ══════════════════════════════════════════

  # Test 19: Filtre par statut actif
  test "filter par statut actif retourne uniquement les utilisateurs actifs" do
    get "/api/users", params: { status: "active" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    json["data"].each do |user|
      assert_equal "active", user["status"]
    end
  end

  # Test 20: Filtre par type Administrator
  test "filter par type Administrator retourne uniquement les admins" do
    get "/api/users", params: { type: "Administrator" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    json["data"].each do |user|
      assert_equal "Administrator", user["type"]
    end
  end

  # Test 21: Filtre par statut bloqué
  test "filter par statut blocked retourne uniquement les utilisateurs bloqués" do
    get "/api/users", params: { status: "blocked" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1
    json["data"].each do |user|
      assert_equal "blocked", user["status"]
    end
  end

  # Test 22: Filtre combiné statut + type
  test "filter combiné statut actif et type Client retourne le bon résultat" do
    get "/api/users", params: { status: "active", type: "Client" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    json["data"].each do |user|
      assert_equal "active", user["status"]
      assert_equal "Client", user["type"]
    end
  end
end
