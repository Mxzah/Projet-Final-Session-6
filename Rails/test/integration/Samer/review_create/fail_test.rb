require "test_helper"

class ReviewCreateFailTest < ActionDispatch::IntegrationTest
  setup do
    @client = users(:valid_user)
    @waiter = users(:waiter_user)
    @admin = users(:admin_user)
  end

  # Non-client cannot create reviews
  test "waiter cannot create review" do
    sign_in @waiter

    assert_no_difference "Review.count" do
      post "/api/reviews", params: {
        review: { rating: 5, comment: "Great!", reviewable_type: "Item", reviewable_id: items(:item_one).id }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
    assert_includes json["errors"], "Only clients can create reviews"
  end

  # Admin cannot create reviews
  test "admin cannot create review" do
    sign_in @admin

    assert_no_difference "Review.count" do
      post "/api/reviews", params: {
        review: { rating: 5, comment: "Great!", reviewable_type: "Item", reviewable_id: items(:item_one).id }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
    assert_includes json["errors"], "Only clients can create reviews"
  end

  # Invalid rating (0) fails
  test "rating below 1 returns success false" do
    sign_in @client

    assert_no_difference "Review.count" do
      post "/api/reviews", params: {
        review: { rating: 0, comment: "Bad!", reviewable_type: "Item", reviewable_id: items(:item_one).id }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
  end

  # Invalid rating (6) fails
  test "rating above 5 returns success false" do
    sign_in @client

    assert_no_difference "Review.count" do
      post "/api/reviews", params: {
        review: { rating: 6, comment: "Amazing!", reviewable_type: "Item", reviewable_id: items(:item_one).id }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
  end

  # Missing comment fails
  test "missing comment returns success false" do
    sign_in @client

    assert_no_difference "Review.count" do
      post "/api/reviews", params: {
        review: { rating: 4, comment: "", reviewable_type: "Item", reviewable_id: items(:item_one).id }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
  end

  # Comment too long fails
  test "comment over 500 chars returns success false" do
    sign_in @client

    assert_no_difference "Review.count" do
      post "/api/reviews", params: {
        review: { rating: 4, comment: "A" * 501, reviewable_type: "Item", reviewable_id: items(:item_one).id }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
  end

  # Whitespace-only comment fails
  test "whitespace-only comment returns success false" do
    sign_in @client

    assert_no_difference "Review.count" do
      post "/api/reviews", params: {
        review: { rating: 4, comment: "   ", reviewable_type: "Item", reviewable_id: items(:item_one).id }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
  end

  # Unordered item fails
  test "review for unordered item returns success false" do
    sign_in @client

    # item_two was never ordered by the client
    assert_no_difference "Review.count" do
      post "/api/reviews", params: {
        review: { rating: 4, comment: "Good!", reviewable_type: "Item", reviewable_id: items(:item_two).id }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
  end

  # Review for non-waiter user fails
  test "review for non-waiter user returns success false" do
    sign_in @client
    cook = users(:cook_user)

    assert_no_difference "Review.count" do
      post "/api/reviews", params: {
        review: { rating: 4, comment: "Nice!", reviewable_type: "User", reviewable_id: cook.id }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
  end

  # Review for waiter who never served the client fails
  test "review for unassigned waiter returns success false" do
    sign_in @client

    # Create a waiter who never served this client
    new_waiter = Waiter.create!(
      first_name: "New", last_name: "Waiter",
      email: "newwaiter@restoqr.ca", password: "password123",
      password_confirmation: "password123"
    )

    assert_no_difference "Review.count" do
      post "/api/reviews", params: {
        review: { rating: 4, comment: "Nice!", reviewable_type: "User", reviewable_id: new_waiter.id }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
  end
end
