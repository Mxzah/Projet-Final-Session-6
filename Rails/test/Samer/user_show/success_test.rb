require "test_helper"

class UserShowSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)
    sign_in @admin
  end

  test "read returns user with all properties" do
    get "/api/users/#{@client.id}"
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    data = json["data"]
    assert_equal @client.id, data["id"]
    assert_equal @client.email, data["email"]
    assert_equal @client.first_name, data["first_name"]
    assert_equal @client.last_name, data["last_name"]
    assert_equal "Client", data["type"]
    assert_equal "active", data["status"]
    assert_not_nil data["created_at"]
    assert data.key?("block_note")
  end
end
