require "test_helper"

class UserIndexSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    sign_in @admin
  end

  test "list returns all users with success true" do
    get "/api/users"
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
    assert_equal User.count, json["data"].length
  end

  test "search by first_name returns matching users" do
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
        "User does not match search 'Jean'"
      )
    end
  end

  test "search by email returns matching users" do
    get "/api/users", params: { search: "test@restoqr" }
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1
  end

  test "sort asc returns users sorted by last_name ascending" do
    get "/api/users", params: { sort: "asc", sort_by: "last_name" }
    assert_response :ok
    json = JSON.parse(response.body)
    names = json["data"].map { |u| u["last_name"] }
    assert_equal names, names.sort
  end

  test "sort desc returns users sorted by last_name descending" do
    get "/api/users", params: { sort: "desc", sort_by: "last_name" }
    assert_response :ok
    json = JSON.parse(response.body)
    names = json["data"].map { |u| u["last_name"] }
    assert_equal names, names.sort.reverse
  end

  test "filter by status active returns only active users" do
    get "/api/users", params: { status: "active" }
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    json["data"].each { |user| assert_equal "active", user["status"] }
  end

  test "filter by type Administrator returns only admins" do
    get "/api/users", params: { type: "Administrator" }
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    json["data"].each { |user| assert_equal "Administrator", user["type"] }
  end

  test "filter by status blocked returns only blocked users" do
    get "/api/users", params: { status: "blocked" }
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1
    json["data"].each { |user| assert_equal "blocked", user["status"] }
  end

  test "combined filter status active and type Client returns correct results" do
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
