require "test_helper"

class TableAvailabilityDestroyFailTest < ActionDispatch::IntegrationTest
  setup do
    @table = tables(:table_one)

    sign_in users(:admin_user)
  end

  test "destroy availability inexistante retourne success false" do
    delete "/api/tables/#{@table.id}/availabilities/999999", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
