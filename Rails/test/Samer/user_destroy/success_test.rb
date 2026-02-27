require "test_helper"

class UserDestroySuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)
    sign_in @admin
  end

  test "delete soft-deletes the user" do
    delete "/api/users/#{@client.id}", as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    user = User.unscoped.find(@client.id)
    assert_not_nil user.deleted_at
  end

  test "soft-deleted user no longer appears in GET /api/users" do
    delete "/api/users/#{@client.id}", as: :json
    assert_response :ok

    # Re-authenticate (session lost after DELETE in integration tests)
    sign_in @admin

    get "/api/users"
    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    ids = json["data"].map { |u| u["id"] }

    # Deleted user is excluded from list
    assert_not_includes ids, @client.id
  end
end
