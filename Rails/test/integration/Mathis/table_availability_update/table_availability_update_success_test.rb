require "test_helper"

class TableAvailabilityUpdateSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @table = tables(:table_one)
    @availability = availabilities(:table_one_availability)

    sign_in users(:admin_user)
  end

  test "update avec des valeurs valides retourne success true" do
    new_start = 3.hours.from_now
    new_end = 2.days.from_now

    put "/api/tables/#{@table.id}/availabilities/#{@availability.id}", params: {
      availability: { start_at: new_start, end_at: new_end, description: "Après mise à jour" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Après mise à jour", json["data"]["description"]

    availability = Availability.find(@availability.id)
    assert_equal "Après mise à jour", availability.description
    assert_in_delta new_start.to_i, availability.start_at.to_i, 1
    assert_in_delta new_end.to_i, availability.end_at.to_i, 1
  end
end
