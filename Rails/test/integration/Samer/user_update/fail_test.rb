require "test_helper"

class UserUpdateFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)
    @waiter = users(:waiter_user)
    sign_in @admin
  end

  test "update with empty first_name returns success false" do
    patch "/api/users/#{@client.id}", params: { user: { first_name: "" } }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    @client.reload
    assert_equal "Jean", @client.first_name
  end

  test "update with whitespace-only first_name returns success false" do
    patch "/api/users/#{@client.id}", params: { user: { first_name: "   " } }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "update with first_name too long returns success false" do
    patch "/api/users/#{@client.id}", params: { user: { first_name: "A" * 51 } }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "update with duplicate email returns success false" do
    patch "/api/users/#{@client.id}", params: { user: { email: @admin.email } }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "update with invalid type returns success false" do
    patch "/api/users/#{@client.id}", params: { user: { type: "SuperAdmin" } }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "update with invalid status returns success false" do
    patch "/api/users/#{@client.id}", params: { user: { status: "suspended" } }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "update with non-existent ID returns success false" do
    patch "/api/users/999999", params: { user: { first_name: "Nouveau" } }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Record not found"
  end

  test "admin cannot update their own account" do
    patch "/api/users/#{@admin.id}", params: { user: { first_name: "Modified" } }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "You cannot modify your own account"
    @admin.reload
    assert_equal "Admin", @admin.first_name
  end

  test "update as client returns success false" do
    sign_out @admin
    sign_in @client
    patch "/api/users/#{@waiter.id}", params: { user: { first_name: "Modified" } }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Access restricted to administrators"
  end
end
