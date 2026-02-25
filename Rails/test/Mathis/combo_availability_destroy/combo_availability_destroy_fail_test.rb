require "test_helper"

class ComboAvailabilityDestroyFailTest < ActionDispatch::IntegrationTest
  setup do
    @combo = combos(:combo_one)

    sign_in users(:admin_user)
  end

  test "destroy availability inexistante retourne success false" do
    delete "/api/combos/#{@combo.id}/availabilities/999999", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
