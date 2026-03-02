require "test_helper"

class UserCreateFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)
    sign_in @admin
  end

  test "create without email returns success false" do
    assert_no_difference "User.count" do
      post "/api/users", params: {
        user: { first_name: "Luc", last_name: "Test", password: "password123", password_confirmation: "password123", type: "Waiter" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create with duplicate email returns success false" do
    assert_no_difference "User.count" do
      post "/api/users", params: {
        user: { first_name: "Autre", last_name: "Test", email: @client.email, password: "password123", password_confirmation: "password123", type: "Waiter" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create with invalid email returns success false" do
    assert_no_difference "User.count" do
      post "/api/users", params: {
        user: { first_name: "Luc", last_name: "Test", email: "not-an-email", password: "password123", password_confirmation: "password123", type: "Waiter" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create without password returns success false" do
    assert_no_difference "User.count" do
      post "/api/users", params: {
        user: { first_name: "Luc", last_name: "Test", email: "luc2@restoqr.ca", type: "Waiter" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create with password too short returns success false" do
    assert_no_difference "User.count" do
      post "/api/users", params: {
        user: { first_name: "Luc", last_name: "Test", email: "luc3@restoqr.ca", password: "abc", password_confirmation: "abc", type: "Waiter" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create with password mismatch returns success false" do
    assert_no_difference "User.count" do
      post "/api/users", params: {
        user: { first_name: "Luc", last_name: "Test", email: "luc4@restoqr.ca", password: "password123", password_confirmation: "different123", type: "Waiter" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create with empty first_name returns success false" do
    assert_no_difference "User.count" do
      post "/api/users", params: {
        user: { first_name: "", last_name: "Test", email: "luc5@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Waiter" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create with whitespace-only first_name returns success false" do
    assert_no_difference "User.count" do
      post "/api/users", params: {
        user: { first_name: "   ", last_name: "Test", email: "luc6@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Waiter" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create with first_name too long returns success false" do
    assert_no_difference "User.count" do
      post "/api/users", params: {
        user: { first_name: "A" * 51, last_name: "Test", email: "luc7@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Waiter" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create with missing last_name returns success false" do
    assert_no_difference "User.count" do
      post "/api/users", params: {
        user: { first_name: "Luc", last_name: "", email: "luc8@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Waiter" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create with invalid type returns success false" do
    assert_no_difference "User.count" do
      post "/api/users", params: {
        user: { first_name: "Luc", last_name: "Test", email: "luc9@restoqr.ca", password: "password123", password_confirmation: "password123", type: "SuperAdmin" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create with invalid status returns success false" do
    assert_no_difference "User.count" do
      post "/api/users", params: {
        user: { first_name: "Luc", last_name: "Test", email: "luc10@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Waiter", status: "suspended" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create with Client type via admin panel returns success false" do
    assert_no_difference "User.count" do
      post "/api/users", params: {
        user: { first_name: "Luc", last_name: "Test", email: "luc11@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Client" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Cannot create Client users from admin panel"
  end

  test "create as client returns success false" do
    sign_out @admin
    sign_in @client
    post "/api/users", params: {
      user: { first_name: "Luc", last_name: "Test", email: "luc12@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Waiter" }
    }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Access restricted to administrators"
  end
end
