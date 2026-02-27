require "test_helper"

class ReviewShowSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @client = users(:valid_user)
    @admin = users(:admin_user)
    @review = reviews(:item_review)
  end

  # Client can see their own review
  test "client can see own review" do
    sign_in @client
    get "/api/reviews/#{@review.id}"

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal @review.id, json["data"]["id"]
    assert_equal @review.rating, json["data"]["rating"]
    assert_equal @review.comment, json["data"]["comment"]
  end

  # Admin can see any review
  test "admin can see any review" do
    sign_in @admin
    get "/api/reviews/#{@review.id}"

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal @review.id, json["data"]["id"]
  end
end
