# frozen_string_literal: true

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
    assert_includes json["errors"], I18n.t("controllers.reviews.only_clients")

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

  # Empty comment is allowed (comment has allow_blank: true)
  test "update with empty comment is accepted" do
    sign_in @client

    patch "/api/reviews/#{@review.id}", params: {
      review: { comment: "" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
  end

  # Whitespace-only comment is allowed (comment has allow_blank: true)
  test "update with whitespace-only comment is accepted" do
    sign_in @client

    patch "/api/reviews/#{@review.id}", params: {
      review: { comment: "   " }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
  end
end
