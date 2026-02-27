require "test_helper"

class ReviewShowFailTest < ActionDispatch::IntegrationTest
  setup do
    @client = users(:valid_user)
    @waiter = users(:waiter_user)
    @review = reviews(:item_review)
  end

  # Non-owner non-admin cannot see review
  test "waiter cannot see client review" do
    sign_in @waiter
    get "/api/reviews/#{@review.id}"

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
    assert_includes json["errors"], "Unauthorized"
  end

  # Non-existent review returns error
  test "non-existent review returns error" do
    sign_in @client
    get "/api/reviews/999999"

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
    assert_includes json["errors"], "Review not found"
  end
end
