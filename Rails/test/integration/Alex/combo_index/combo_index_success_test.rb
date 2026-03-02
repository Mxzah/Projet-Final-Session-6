require "test_helper"

class ComboIndexSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @combo1 = combos(:combo_one)
    @combo2 = combos(:combo_two)
    @combo3 = combos(:combo_three)
  end

  # Test 1: GET /api/combos sans être connecté retourne la liste
  test "index sans être connecté retourne success true" do
    get "/api/combos", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_kind_of Array, json["data"]
  end

  # Test 2: GET /api/combos avec admin retourne la liste
  test "index avec admin retourne success true" do
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    get "/api/combos", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end

  # Test 3: GET /api/combos retourne les availabilities
  test "index retourne les availabilities" do
    get "/api/combos", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    json["data"].each do |combo|
      assert combo.key?("availabilities")
    end
  end

  # Test 4: GET /api/combos retourne les champs attendus
  test "index retourne les champs attendus" do
    get "/api/combos", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    combo = json["data"].first
    assert combo.key?("id")
    assert combo.key?("name")
    assert combo.key?("description")
    assert combo.key?("price")
    assert combo.key?("image_url")
    assert combo.key?("created_at")
    assert combo.key?("availabilities")
  end
end
