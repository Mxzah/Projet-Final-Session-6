require "test_helper"

class ComboAvailabilityDestroySuccessTest < ActionDispatch::IntegrationTest
  setup do
    @combo = combos(:combo_one)
    @availability = availabilities(:combo_one_availability)

    sign_in users(:admin_user)
  end

  test "destroy supprime l'availability et retourne success true" do
    assert Availability.exists?(id: @availability.id)

    delete "/api/combos/#{@combo.id}/availabilities/#{@availability.id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not Availability.exists?(id: @availability.id)
  end
end
