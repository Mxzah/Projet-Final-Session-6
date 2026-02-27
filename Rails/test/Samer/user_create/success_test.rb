require "test_helper"

class UserCreateSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    sign_in @admin
  end

  test "create an Administrator with valid fields returns 200" do
    assert_difference "User.count", 1 do
      post "/api/users", params: {
        user: { first_name: "Julie", last_name: "Martin", email: "julie@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Administrator" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Administrator", json["data"]["type"]
    created = User.find(json["data"]["id"])
    assert_equal "julie@restoqr.ca", created.email
    assert_equal "Administrator", created.type
  end

  test "create a Waiter with valid fields returns 200" do
    assert_difference "User.count", 1 do
      post "/api/users", params: {
        user: { first_name: "Paul", last_name: "Simard", email: "paul@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Waiter" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Waiter", json["data"]["type"]
  end

  test "create a Cook with valid fields returns 200" do
    assert_difference "User.count", 1 do
      post "/api/users", params: {
        user: { first_name: "Anne", last_name: "Bouchard", email: "anne@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Cook" }
      }, as: :json
    end
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Cook", json["data"]["type"]
  end

  test "create includes block_note field" do
    post "/api/users", params: {
      user: { first_name: "Luc", last_name: "Bergeron", email: "luc@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Waiter", block_note: "Test note" }
    }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Test note", json["data"]["block_note"]
    created = User.find(json["data"]["id"])
    assert_equal "Test note", created.block_note
  end
end
