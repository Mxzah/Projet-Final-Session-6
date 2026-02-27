require "test_helper"

class ReviewCreateSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @client = users(:valid_user)
    sign_in @client
  end

  # Client can create an item review
  test "client creates item review" do
    item = items(:item_one)

    assert_difference "Review.count", 1 do
      post "/api/reviews", params: {
        review: { rating: 5, comment: "Delicious tartare!", reviewable_type: "Item", reviewable_id: item.id }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal 5, json["data"]["rating"]
    assert_equal "Delicious tartare!", json["data"]["comment"]
    assert_equal "Item", json["data"]["reviewable_type"]
    assert_equal item.id, json["data"]["reviewable_id"]

    # Database state
    review = Review.find(json["data"]["id"])
    assert_equal @client.id, review.user_id
    assert_equal 5, review.rating
  end

  # Client can create a combo review
  test "client creates combo review" do
    combo = combos(:combo_one)

    assert_difference "Review.count", 1 do
      post "/api/reviews", params: {
        review: { rating: 4, comment: "Great combo deal!", reviewable_type: "Combo", reviewable_id: combo.id }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal "Combo", json["data"]["reviewable_type"]
    assert_equal combo.id, json["data"]["reviewable_id"]
  end

  # Client can create a server review
  test "client creates server review" do
    waiter = users(:waiter_user)

    assert_difference "Review.count", 1 do
      post "/api/reviews", params: {
        review: { rating: 5, comment: "Best server ever!", reviewable_type: "User", reviewable_id: waiter.id }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal "User", json["data"]["reviewable_type"]
    assert_equal waiter.id, json["data"]["reviewable_id"]
    assert_not_nil json["data"]["reviewable_name"]
  end
end
