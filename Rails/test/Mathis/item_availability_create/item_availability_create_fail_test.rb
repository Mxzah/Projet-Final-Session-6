require "test_helper"

class ItemAvailabilityCreateFailTest < ActionDispatch::IntegrationTest
  setup do
    @item = items(:item_two)
    @item.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")), filename: "test.jpg", content_type: "image/jpeg")
    @client = users(:valid_user)

    sign_in users(:admin_user)
  end

  test "create sans start_at retourne success false" do
    assert_no_difference -> { Availability.where(available_type: "Item", available_id: @item.id).count } do
      post "/api/items/#{@item.id}/availabilities", params: {
        availability: { end_at: 1.day.from_now, description: "Test" }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create avec start_at dans le passé retourne success false" do
    assert_no_difference -> { Availability.where(available_type: "Item", available_id: @item.id).count } do
      post "/api/items/#{@item.id}/availabilities", params: {
        availability: { start_at: 1.day.ago, end_at: 1.day.from_now, description: "Test" }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create avec end_at avant start_at retourne success false" do
    assert_no_difference -> { Availability.where(available_type: "Item", available_id: @item.id).count } do
      post "/api/items/#{@item.id}/availabilities", params: {
        availability: { start_at: 1.day.from_now, end_at: 2.hours.from_now, description: "Test" }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create avec durée inférieure à 1 heure retourne success false" do
    start = 1.day.from_now
    assert_no_difference -> { Availability.where(available_type: "Item", available_id: @item.id).count } do
      post "/api/items/#{@item.id}/availabilities", params: {
        availability: { start_at: start, end_at: start + 30.minutes, description: "Test" }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create avec description trop longue retourne success false" do
    assert_no_difference -> { Availability.where(available_type: "Item", available_id: @item.id).count } do
      post "/api/items/#{@item.id}/availabilities", params: {
        availability: { start_at: 2.hours.from_now, end_at: 1.day.from_now, description: "A" * 256 }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create avec périodes chevauchantes retourne success false" do
    item_one = items(:item_one)
    item_one.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")), filename: "test.jpg", content_type: "image/jpeg")

    assert_no_difference -> { Availability.where(available_type: "Item", available_id: item_one.id).count } do
      post "/api/items/#{item_one.id}/availabilities", params: {
        availability: { start_at: 6.hours.from_now, end_at: 2.days.from_now, description: "Chevauchement" }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "create avec un compte client retourne success false" do
    sign_out :user
    sign_in @client

    assert_no_difference -> { Availability.where(available_type: "Item", available_id: @item.id).count } do
      post "/api/items/#{@item.id}/availabilities", params: {
        availability: { start_at: 2.hours.from_now, end_at: 1.day.from_now, description: "Test" }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Access restricted to administrators"
  end
end
