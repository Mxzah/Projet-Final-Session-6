require "test_helper"

class ReviewDestroyFailTest < ActionDispatch::IntegrationTest
  setup do
    @client = users(:valid_user)
    @waiter = users(:waiter_user)
    @review = reviews(:item_review)
  end

  # Another user (non-admin, non-owner) cannot delete a review
  test "waiter cannot delete client review" do
    sign_in @waiter

    delete "/api/reviews/#{@review.id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
    assert_includes json["errors"], "Unauthorized"

    # Database state: not deleted
    review = Review.unscoped.find(@review.id)
    assert_nil review.deleted_at
  end

  # Unauthenticated user cannot delete
  test "unauthenticated user cannot delete review" do
    delete "/api/reviews/#{@review.id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
  end

  # Non-existent review returns error
  test "delete non-existent review returns error" do
    sign_in @client

    delete "/api/reviews/999999", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
    assert_includes json["errors"], "Review not found"
  end
end
