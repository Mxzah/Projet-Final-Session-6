require "test_helper"

class ItemAvailabilityCreateSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @item = items(:item_two)
    @item.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")), filename: "test.jpg", content_type: "image/jpeg")
    @fixture_full = availabilities(:item_two_create_full)
    @fixture_open = availabilities(:item_two_create_open)

    # Supprimer les fixtures pour pouvoir les recréer via POST
    @fixture_full.destroy!
    @fixture_open.destroy!

    sign_in users(:admin_user)
  end

  test "create avec tous les champs valides retourne success true" do
    post "/api/items/#{@item.id}/availabilities", params: {
      availability: { start_at: @fixture_full.start_at, end_at: @fixture_full.end_at, description: @fixture_full.description }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not_nil json["data"]["id"]
    assert_equal @fixture_full.description, json["data"]["description"]

    availability = Availability.find(json["data"]["id"])
    assert_equal "Item", availability.available_type
    assert_equal @item.id, availability.available_id
    assert_equal @fixture_full.description, availability.description
    assert_not_nil availability.start_at
    assert_not_nil availability.end_at
  end

  test "create sans end_at crée une availability ouverte" do
    post "/api/items/#{@item.id}/availabilities", params: {
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
