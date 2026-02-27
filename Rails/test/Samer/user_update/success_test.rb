require "test_helper"

class UserUpdateSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)
    sign_in @admin
  end

  test "update modifies first_name and last_name" do
    patch "/api/users/#{@client.id}", params: {
      user: { first_name: "Jean-Pierre", last_name: "Tremblay-Roy" }
    }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Jean-Pierre", json["data"]["first_name"]
    assert_equal "Tremblay-Roy", json["data"]["last_name"]
    @client.reload
    assert_equal "Jean-Pierre", @client.first_name
    assert_equal "Tremblay-Roy", @client.last_name
  end

  test "update modifies email" do
    patch "/api/users/#{@client.id}", params: {
      user: { email: "nouveau@restoqr.ca" }
    }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "nouveau@restoqr.ca", json["data"]["email"]
    @client.reload
    assert_equal "nouveau@restoqr.ca", @client.email
  end

  test "update modifies type" do
    patch "/api/users/#{@client.id}", params: {
      user: { type: "Waiter" }
    }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Waiter", json["data"]["type"]
    # Use User.find (not reload) to avoid STI class mismatch
    updated = User.find(@client.id)
    assert_equal "Waiter", updated.type
  end

  test "update modifies status" do
    patch "/api/users/#{@client.id}", params: {
      user: { status: "blocked" }
    }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "blocked", json["data"]["status"]
    @client.reload
    assert_equal "blocked", @client.status
  end

  test "update without password does not change password" do
    patch "/api/users/#{@client.id}", params: {
      user: { first_name: "Nouveau" }
    }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Nouveau", json["data"]["first_name"]
    sign_out @admin
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json
    login_json = JSON.parse(response.body)
    assert login_json["success"]
  end

  test "update with blank password does not change password" do
    patch "/api/users/#{@client.id}", params: {
      user: { first_name: "Autre", password: "", password_confirmation: "" }
    }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Autre", json["data"]["first_name"]
  end

  test "update block_note" do
    patch "/api/users/#{@client.id}", params: {
      user: { block_note: "Blocked for spamming" }
    }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Blocked for spamming", json["data"]["block_note"]
    @client.reload
    assert_equal "Blocked for spamming", @client.block_note
  end
end
