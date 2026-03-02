require "test_helper"

class ItemAvailabilityIndexSuccessTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin_user)
  end

  test "index retourne une liste vide quand aucune availability" do
    @item = items(:item_three)
    @item.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")), filename: "test.jpg", content_type: "image/jpeg")

    get "/api/items/#{@item.id}/availabilities", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_kind_of Array, json["data"]
    assert_equal 0, json["data"].length
    assert_equal 0, Availability.where(available_type: "Item", available_id: @item.id).count
  end

  test "index retourne les availabilities des fixtures" do
    @item = items(:item_one)
    @item.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")), filename: "test.jpg", content_type: "image/jpeg")

    get "/api/items/#{@item.id}/availabilities", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 2, json["data"].length
    assert_equal 2, Availability.where(available_type: "Item", available_id: @item.id).count
  end
end
