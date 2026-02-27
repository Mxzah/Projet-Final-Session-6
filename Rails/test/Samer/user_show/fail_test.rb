require "test_helper"

class UserShowFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)
    sign_in @admin
  end

  test "read with non-existent ID returns success false" do
    get "/api/users/999999", as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Record not found"
  end
end
