require "test_helper"

class UserIndexFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)
  end

  test "list as client returns success false" do
    sign_in @client
    get "/api/users"
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Access restricted to administrators"
  end

  test "search with no results returns empty array" do
    sign_in @admin
    get "/api/users", params: { search: "zzzzzzzzzzz" }
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  test "filter with non-existent type returns empty array" do
    sign_in @admin
    get "/api/users", params: { type: "Ninja" }
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  test "filter with non-existent status returns empty array" do
    sign_in @admin
    get "/api/users", params: { status: "suspended" }
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end
end
