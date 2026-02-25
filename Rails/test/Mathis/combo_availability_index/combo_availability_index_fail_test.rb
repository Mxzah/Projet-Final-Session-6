require "test_helper"

class ComboAvailabilityIndexFailTest < ActionDispatch::IntegrationTest
  setup do
    @combo = combos(:combo_one)
  end

  test "index sans être connecté retourne success false" do
    get "/api/combos/#{@combo.id}/availabilities", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "index avec un compte client retourne success false" do
    sign_in users(:valid_user)

    get "/api/combos/#{@combo.id}/availabilities", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Access restricted to administrators"
  end

  test "index avec un compte serveur retourne success false" do
    sign_in users(:waiter_user)

    get "/api/combos/#{@combo.id}/availabilities", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Access restricted to administrators"
  end
end
