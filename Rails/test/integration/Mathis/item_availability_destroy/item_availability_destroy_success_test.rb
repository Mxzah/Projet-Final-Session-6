require "test_helper"

class ItemAvailabilityDestroySuccessTest < ActionDispatch::IntegrationTest
  setup do
    @item = items(:item_one)
    @item.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")), filename: "test.jpg", content_type: "image/jpeg")
    @availability = availabilities(:item_one_availability)

    sign_in users(:admin_user)
  end

  test "destroy supprime l'availability et retourne success true" do
    assert Availability.exists?(id: @availability.id)

    delete "/api/items/#{@item.id}/availabilities/#{@availability.id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not Availability.exists?(id: @availability.id)
  end
end
