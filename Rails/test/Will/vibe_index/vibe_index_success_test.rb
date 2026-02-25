require "test_helper"

class VibeIndexSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    @vibe = Vibe.create!(name: "Festive", color: "#FF5733")
  end

  # Test 1: Returns 200 and success true
  test "index returns success true and data as array" do
    get "/api/vibes", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
    assert_equal [], json["errors"]
  end

  # Test 2: Vibes have expected fields
  test "index returns vibes with id name and color fields" do
    get "/api/vibes", as: :json

    json = JSON.parse(response.body)
    assert json["data"].length >= 1
    vibe = json["data"].first
    assert vibe.key?("id")
    assert vibe.key?("name")
    assert vibe.key?("color")
  end

  # Test 3: Returns the correct vibe data
  test "index returns correct vibe name and color" do
    get "/api/vibes", as: :json

    json = JSON.parse(response.body)
    vibe = json["data"].find { |v| v["id"] == @vibe.id }
    assert_not_nil vibe
    assert_equal "Festive", vibe["name"]
    assert_equal "#FF5733", vibe["color"]
  end

  # Test 4: Also accessible by admin
  test "index also returns vibes for admin user" do
    delete "/users/sign_out", as: :json
    post "/users/sign_in", params: { user: { email: users(:admin_user).email, password: "password123" } }, as: :json

    get "/api/vibes", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1
  end
end
