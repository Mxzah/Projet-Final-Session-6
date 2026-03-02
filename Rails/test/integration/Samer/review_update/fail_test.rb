require "test_helper"

class ReviewUpdateFailTest < ActionDispatch::IntegrationTest
  setup do
    @client = users(:valid_user)
    @waiter = users(:waiter_user)
    @review = reviews(:item_review)
  end

  # Another user cannot update someone else's review
  test "waiter cannot update client review" do
    sign_in @waiter

    patch "/api/reviews/#{@review.id}", params: {
      review: { rating: 1 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
    assert_includes json["errors"], "You can only update your own reviews"

    # Database state: unchanged
    @review.reload
    assert_equal 4, @review.rating
  end

  # Invalid rating fails
  test "update with invalid rating returns success false" do
    sign_in @client

    patch "/api/reviews/#{@review.id}", params: {
      review: { rating: 0 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
  end

  # Empty comment fails
  test "update with empty comment returns success false" do
    sign_in @client

    patch "/api/reviews/#{@review.id}", params: {
      review: { comment: "" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
  end

  # Whitespace-only comment fails
  test "update with whitespace-only comment returns success false" do
    sign_in @client

    patch "/api/reviews/#{@review.id}", params: {
      review: { comment: "   " }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
  end
end
