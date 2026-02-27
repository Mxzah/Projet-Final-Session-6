require "test_helper"

class ReviewIndexFailTest < ActionDispatch::IntegrationTest
  # Unauthenticated user cannot list reviews
  test "unauthenticated user cannot list reviews" do
    get "/api/reviews"

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
  end
end
