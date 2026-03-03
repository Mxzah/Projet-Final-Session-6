require "test_helper"

class VibeIndexFailTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
  end

  # Test 1: Vibes index is public — works without authentication
  test "index without authentication still returns success true" do
    delete "/users/sign_out", as: :json

    get "/api/vibes", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
  end
end
