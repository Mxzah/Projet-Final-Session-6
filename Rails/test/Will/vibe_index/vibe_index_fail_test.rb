require "test_helper"

class VibeIndexFailTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
  end

  # Test 1: Not authenticated returns success false
  test "index without authentication returns success false" do
    delete "/users/sign_out", as: :json

    get "/api/vibes", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end
end
