require "test_helper"

class TableAvailabilityDestroySuccessTest < ActionDispatch::IntegrationTest
  setup do
    @table = tables(:table_one)
    @availability = availabilities(:table_one_availability)

    sign_in users(:admin_user)
  end

  test "destroy supprime l'availability et retourne success true" do
    assert Availability.exists?(id: @availability.id)

    delete "/api/tables/#{@table.id}/availabilities/#{@availability.id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not Availability.exists?(id: @availability.id)
  end
end
