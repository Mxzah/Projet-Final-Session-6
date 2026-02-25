require "test_helper"

class CategoryAvailabilityDestroyFailTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:entrees)

    sign_in users(:admin_user)
  end

  test "destroy availability inexistante retourne success false" do
    delete "/api/categories/#{@category.id}/availabilities/999999", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
