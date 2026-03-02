require "test_helper"

class ComboAvailabilityCreateSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @combo = combos(:combo_two)
    @fixture_full = availabilities(:combo_two_create_full)
    @fixture_open = availabilities(:combo_two_create_open)

    # Supprimer les fixtures pour pouvoir les recréer via POST
    @fixture_full.destroy!
    @fixture_open.destroy!

    sign_in users(:admin_user)
  end

  test "create avec tous les champs valides retourne success true" do
    post "/api/combos/#{@combo.id}/availabilities", params: {
      availability: { start_at: @fixture_full.start_at, end_at: @fixture_full.end_at, description: @fixture_full.description }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not_nil json["data"]["id"]
    assert_equal @fixture_full.description, json["data"]["description"]

    availability = Availability.find(json["data"]["id"])
    assert_equal "Combo", availability.available_type
    assert_equal @combo.id, availability.available_id
    assert_equal @fixture_full.description, availability.description
    assert_not_nil availability.start_at
    assert_not_nil availability.end_at
  end

  test "create sans end_at crée une availability ouverte" do
    post "/api/combos/#{@combo.id}/availabilities", params: {
      availability: { start_at: @fixture_open.start_at, description: @fixture_open.description }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    availability = Availability.find(json["data"]["id"])
    assert_nil availability.end_at
    assert_equal @fixture_open.description, availability.description
  end
end
