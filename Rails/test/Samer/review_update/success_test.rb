require "test_helper"

class ReviewUpdateSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @client = users(:valid_user)
    @review = reviews(:item_review)
    sign_in @client
  end

  # Client can update their own review rating
  test "client updates review rating" do
    patch "/api/reviews/#{@review.id}", params: {
      review: { rating: 5 }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal 5, json["data"]["rating"]

    # Database state
    @review.reload
    assert_equal 5, @review.rating
  end

  # Client can update their own review comment
  test "client updates review comment" do
    patch "/api/reviews/#{@review.id}", params: {
      review: { comment: "Updated comment about the tartare" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal "Updated comment about the tartare", json["data"]["comment"]

    # Database state
    @review.reload
    assert_equal "Updated comment about the tartare", @review.comment
  end
end
