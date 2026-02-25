require "test_helper"

class CategoryAvailabilityIndexFailTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:entrees)
  end

  test "index sans être connecté retourne success false" do
    get "/api/categories/#{@category.id}/availabilities", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "index avec un compte client retourne success false" do
    sign_in users(:valid_user)

    get "/api/categories/#{@category.id}/availabilities", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Access restricted to administrators"
  end

  test "index avec un compte serveur retourne success false" do
    sign_in users(:waiter_user)

    get "/api/categories/#{@category.id}/availabilities", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Access restricted to administrators"
  end
end
