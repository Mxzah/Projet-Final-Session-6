require "test_helper"

class ComboAvailabilityIndexSuccessTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin_user)
  end

  test "index retourne une liste vide quand aucune availability" do
    @combo = combos(:combo_three)

    get "/api/combos/#{@combo.id}/availabilities", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_kind_of Array, json["data"]
    assert_equal 0, json["data"].length
    assert_equal 0, Availability.where(available_type: "Combo", available_id: @combo.id).count
  end

  test "index retourne les availabilities des fixtures" do
    @combo = combos(:combo_one)

    get "/api/combos/#{@combo.id}/availabilities", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 2, json["data"].length
    assert_equal 2, Availability.where(available_type: "Combo", available_id: @combo.id).count
  end
end
