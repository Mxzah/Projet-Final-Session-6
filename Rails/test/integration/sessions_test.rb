require "test_helper"

class SessionsTest < ActionDispatch::IntegrationTest
  # Test 1: Connexion réussie avec credentials valides
  test "login avec credentials valides retourne success true" do
    user = users(:valid_user)

    post "/users/sign_in", params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }, as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal user.email, json_response["data"]["email"]
    assert_equal user.first_name, json_response["data"]["first_name"]
    assert_equal user.last_name, json_response["data"]["last_name"]
    assert_equal user.type, json_response["data"]["type"]
  end

  # Test 2: Connexion échouée avec mauvais mot de passe
  test "login avec mauvais mot de passe retourne success false" do
    user = users(:valid_user)

    post "/users/sign_in", params: {
      user: {
        email: user.email,
        password: "wrongpassword"
      }
    }, as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_includes json_response["errors"], "Email ou mot de passe invalide"
  end

  # Test 3: Connexion échouée avec email inexistant
  test "login avec email inexistant retourne success false" do
    post "/users/sign_in", params: {
      user: {
        email: "inexistant@restoqr.ca",
        password: "password123"
      }
    }, as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_includes json_response["errors"], "Email ou mot de passe invalide"
  end

  # Test 4: Connexion échouée avec utilisateur inactif
  test "login avec utilisateur inactif retourne une erreur" do
    user = users(:inactive_user)

    post "/users/sign_in", params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }, as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert json_response["errors"].any?, "Should have errors"
  end
end
