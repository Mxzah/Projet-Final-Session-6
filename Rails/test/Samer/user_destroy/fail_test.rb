require "test_helper"

class UserDestroyFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)
    @waiter = users(:waiter_user)
    sign_in @admin
  end

  test "admin cannot delete their own account" do
    delete "/api/users/#{@admin.id}", as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "You cannot delete your own account"
    @admin.reload
    assert_nil @admin.deleted_at
  end

  test "cannot delete the last administrator" do
    assert_equal 1, Administrator.count
    post "/api/users", params: {
      user: { first_name: "New", last_name: "Admin", email: "newadmin@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Administrator" }
    }, as: :json
    new_admin = JSON.parse(response.body)["data"]
    sign_out @admin
    sign_in User.find(new_admin["id"])
    delete "/api/users/#{@admin.id}", as: :json
    json = JSON.parse(response.body)
    assert json["success"]
  end

  test "delete with non-existent ID returns success false" do
    delete "/api/users/999999", as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Record not found"
  end

  test "delete as client returns success false" do
    sign_out @admin
    sign_in @client
    delete "/api/users/#{@waiter.id}", as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Access restricted to administrators"
  end
end
