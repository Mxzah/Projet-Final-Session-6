require "test_helper"

class ReviewDestroySuccessTest < ActionDispatch::IntegrationTest
  setup do
    @client = users(:valid_user)
    @admin = users(:admin_user)
    @review = reviews(:item_review)
  end

  # Client can delete their own review (soft delete)
  test "client soft-deletes own review" do
    sign_in @client

    delete "/api/reviews/#{@review.id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]

    # Database state: deleted_at is set
    review = Review.unscoped.find(@review.id)
    assert_not_nil review.deleted_at
  end

  # Admin can delete any review
  test "admin soft-deletes any review" do
    sign_in @admin
    server_review = reviews(:server_review)

    delete "/api/reviews/#{server_review.id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]

    # Database state: deleted_at is set
    review = Review.unscoped.find(server_review.id)
    assert_not_nil review.deleted_at
  end
end
