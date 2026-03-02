require "test_helper"

class ItemAvailabilityDestroyFailTest < ActionDispatch::IntegrationTest
  setup do
    @item = items(:item_one)
    @item.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")), filename: "test.jpg", content_type: "image/jpeg")

    sign_in users(:admin_user)
  end

  test "destroy availability inexistante retourne success false" do
    assert_no_difference -> { Availability.where(available_type: "Item", available_id: @item.id).count } do
      delete "/api/items/#{@item.id}/availabilities/999999", as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
