require "test_helper"

class UserFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)
    @waiter = users(:waiter_user)

    # Connexion admin
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json
  end

  # ══════════════════════════════════════════
  # CREATE - Tests négatifs
  # ══════════════════════════════════════════

  # Test 1: Create sans email
  test "create sans email retourne success false" do
    post "/api/users", params: {
      user: { first_name: "Luc", last_name: "Test", password: "password123", password_confirmation: "password123", type: "Client" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 2: Create avec email dupliqué
  test "create avec email dupliqué retourne success false" do
    post "/api/users", params: {
      user: { first_name: "Autre", last_name: "Test", email: @client.email, password: "password123", password_confirmation: "password123", type: "Client" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 3: Create avec email invalide
  test "create avec email invalide retourne success false" do
    post "/api/users", params: {
      user: { first_name: "Luc", last_name: "Test", email: "pas-un-email", password: "password123", password_confirmation: "password123", type: "Client" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 4: Create sans password
  test "create sans password retourne success false" do
    post "/api/users", params: {
      user: { first_name: "Luc", last_name: "Test", email: "luc2@restoqr.ca", type: "Client" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 5: Create avec password trop court
  test "create avec password trop court retourne success false" do
    post "/api/users", params: {
      user: { first_name: "Luc", last_name: "Test", email: "luc3@restoqr.ca", password: "abc", password_confirmation: "abc", type: "Client" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 6: Create avec password mismatch
  test "create avec password mismatch retourne success false" do
    post "/api/users", params: {
      user: { first_name: "Luc", last_name: "Test", email: "luc4@restoqr.ca", password: "password123", password_confirmation: "different123", type: "Client" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 7: Create avec prénom vide
  test "create avec prénom vide retourne success false" do
    post "/api/users", params: {
      user: { first_name: "", last_name: "Test", email: "luc5@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Client" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 8: Create avec prénom uniquement d'espaces
  test "create avec prénom uniquement d'espaces retourne success false" do
    post "/api/users", params: {
      user: { first_name: "   ", last_name: "Test", email: "luc6@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Client" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 9: Create avec prénom trop long (> 50 caractères)
  test "create avec prénom trop long retourne success false" do
    post "/api/users", params: {
      user: { first_name: "A" * 51, last_name: "Test", email: "luc7@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Client" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 10: Create avec nom manquant
  test "create avec nom manquant retourne success false" do
    post "/api/users", params: {
      user: { first_name: "Luc", last_name: "", email: "luc8@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Client" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 11: Create avec type invalide
  test "create avec type invalide retourne success false" do
    post "/api/users", params: {
      user: { first_name: "Luc", last_name: "Test", email: "luc9@restoqr.ca", password: "password123", password_confirmation: "password123", type: "SuperAdmin" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 12: Create avec statut invalide
  test "create avec statut invalide retourne success false" do
    post "/api/users", params: {
      user: { first_name: "Luc", last_name: "Test", email: "luc10@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Client", status: "suspendu" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # ══════════════════════════════════════════
  # READ - Tests négatifs
  # ══════════════════════════════════════════

  # Test 13: Read avec ID inexistant
  test "read avec ID inexistant retourne success false" do
    get "/api/users/999999", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Utilisateur introuvable"
  end

  # ══════════════════════════════════════════
  # UPDATE - Tests négatifs
  # ══════════════════════════════════════════

  # Test 14: Update avec prénom vide
  test "update avec prénom vide retourne success false" do
    patch "/api/users/#{@client.id}", params: {
      user: { first_name: "" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 15: Update avec prénom uniquement d'espaces
  test "update avec prénom uniquement d'espaces retourne success false" do
    patch "/api/users/#{@client.id}", params: {
      user: { first_name: "   " }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 16: Update avec prénom trop long
  test "update avec prénom trop long retourne success false" do
    patch "/api/users/#{@client.id}", params: {
      user: { first_name: "A" * 51 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 17: Update avec email dupliqué
  test "update avec email dupliqué retourne success false" do
    patch "/api/users/#{@client.id}", params: {
      user: { email: @admin.email }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 18: Update avec type invalide
  test "update avec type invalide retourne success false" do
    patch "/api/users/#{@client.id}", params: {
      user: { type: "SuperAdmin" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 19: Update avec statut invalide
  test "update avec statut invalide retourne success false" do
    patch "/api/users/#{@client.id}", params: {
      user: { status: "suspendu" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 20: Update avec ID inexistant
  test "update avec ID inexistant retourne success false" do
    patch "/api/users/999999", params: {
      user: { first_name: "Nouveau" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Utilisateur introuvable"
  end

  # ══════════════════════════════════════════
  # DELETE - Tests négatifs
  # ══════════════════════════════════════════

  # Test 21: Delete avec ID inexistant
  test "delete avec ID inexistant retourne success false" do
    delete "/api/users/999999", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Utilisateur introuvable"
  end

  # ══════════════════════════════════════════
  # AUTORISATION - Tests non-admin
  # ══════════════════════════════════════════

  # Test 22: List avec un compte client retourne success false
  test "list avec un compte client retourne success false" do
    delete "/users/sign_out", as: :json
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    get "/api/users"

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Accès réservé aux administrateurs"
  end

  # Test 23: Create avec un compte client retourne success false
  test "create avec un compte client retourne success false" do
    delete "/users/sign_out", as: :json
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    post "/api/users", params: {
      user: { first_name: "Luc", last_name: "Test", email: "luc11@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Client" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Accès réservé aux administrateurs"
  end

  # Test 24: Update avec un compte client retourne success false
  test "update avec un compte client retourne success false" do
    delete "/users/sign_out", as: :json
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    patch "/api/users/#{@waiter.id}", params: {
      user: { first_name: "Modifié" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Accès réservé aux administrateurs"
  end

  # Test 25: Delete avec un compte client retourne success false
  test "delete avec un compte client retourne success false" do
    delete "/users/sign_out", as: :json
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    delete "/api/users/#{@waiter.id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Accès réservé aux administrateurs"
  end

  # ══════════════════════════════════════════
  # SEARCH/FILTER - Edge cases
  # ══════════════════════════════════════════

  # Test 26: Recherche sans résultat
  test "search sans résultat retourne un tableau vide" do
    get "/api/users", params: { search: "zzzzzzzzzzz" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  # Test 27: Filtre avec type inexistant retourne un tableau vide
  test "filter avec type inexistant retourne un tableau vide" do
    get "/api/users", params: { type: "Ninja" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  # Test 28: Filtre avec statut inexistant retourne un tableau vide
  test "filter avec statut inexistant retourne un tableau vide" do
    get "/api/users", params: { status: "suspendu" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end
end
