require "test_helper"

class ComboAvailabilityUpdateFailTest < ActionDispatch::IntegrationTest
  setup do
    @combo = combos(:combo_one)
    @availability = availabilities(:combo_one_availability)
    @availability_two = availabilities(:combo_one_availability_two)
    @client = users(:valid_user)

    sign_in users(:admin_user)
  end

  test "update sans start_at retourne success false" do
    put "/api/combos/#{@combo.id}/availabilities/#{@availability.id}", params: {
      availability: { start_at: nil }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]

    availability = Availability.find(@availability.id)
    assert_not_nil availability.start_at
  end

  test "update avec start_at dans le passé retourne success false" do
    put "/api/combos/#{@combo.id}/availabilities/#{@availability.id}", params: {
      availability: { start_at: 1.day.ago }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "update avec end_at avant start_at retourne success false" do
    put "/api/combos/#{@combo.id}/availabilities/#{@availability.id}", params: {
      availability: { start_at: 1.day.from_now, end_at: 2.hours.from_now }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "update avec durée inférieure à 1 heure retourne success false" do
    start = 1.day.from_now
    put "/api/combos/#{@combo.id}/availabilities/#{@availability.id}", params: {
      availability: { start_at: start, end_at: start + 30.minutes }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "update avec description trop longue retourne success false" do
    put "/api/combos/#{@combo.id}/availabilities/#{@availability.id}", params: {
      availability: { description: "A" * 256 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "update avec périodes chevauchantes retourne success false" do
    put "/api/combos/#{@combo.id}/availabilities/#{@availability_two.id}", params: {
      availability: { start_at: 6.hours.from_now, end_at: 12.hours.from_now }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "update avec un compte client retourne success false" do
    sign_out :user
    sign_in @client

    put "/api/combos/#{@combo.id}/availabilities/#{@availability.id}", params: {
      availability: { description: "Modifié par client" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Access restricted to administrators"

    availability = Availability.find(@availability.id)
    assert_equal "Disponibilité combo 1", availability.description
  end
end
