require "test_helper"

class ReviewIndexSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @client = users(:valid_user)
    @admin = users(:admin_user)
  end

  # Client sees only their own reviews
  test "client sees own reviews" do
    sign_in @client
    get "/api/reviews"

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_instance_of Array, json["data"]

    # All returned reviews belong to the client
    json["data"].each do |review|
      assert_equal @client.id, review["user_id"]
    end
  end

  # Admin sees all reviews
  test "admin sees all reviews" do
    sign_in @admin
    get "/api/reviews"

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]

    # Database state: admin sees all reviews in DB
    assert_equal Review.count, json["data"].length
  end

  # Filter by reviewable_type works
  test "filter by reviewable_type Item returns only item reviews" do
    sign_in @admin
    get "/api/reviews", params: { reviewable_type: "Item" }

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    json["data"].each do |review|
      assert_equal "Item", review["reviewable_type"]
    end
  end

  # Filter by rating works
  test "filter by rating returns correct reviews" do
    sign_in @admin
    get "/api/reviews", params: { rating: "5" }

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    json["data"].each do |review|
      assert_equal 5, review["rating"]
    end
  end

  # Sort by oldest works
  test "sort by oldest returns reviews in ascending order" do
    sign_in @admin
    get "/api/reviews", params: { sort: "oldest" }

    assert_response :ok
    json = JSON.parse(response.body)

    # Verify ascending order
    assert json["success"]
    dates = json["data"].map { |r| r["created_at"] }
    assert_equal dates, dates.sort
  end

  # Sort by rating_high works
  test "sort by rating_high returns reviews in descending rating order" do
    sign_in @admin
    get "/api/reviews", params: { sort: "rating_high" }

    assert_response :ok
    json = JSON.parse(response.body)

    # Verify descending rating order
    assert json["success"]
    ratings = json["data"].map { |r| r["rating"] }
    assert_equal ratings, ratings.sort.reverse
  end

  # Search by user name works (admin only)
  test "admin search by user name returns matching reviews" do
    sign_in @admin
    get "/api/reviews", params: { search: "Jean" }

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert json["data"].length >= 1
  end

  # Review JSON includes enriched fields
  test "review JSON includes user_name and reviewable_name" do
    sign_in @client
    get "/api/reviews"

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response structure
    assert json["success"]
    review = json["data"].first
    assert_not_nil review["user_name"]
    assert_not_nil review["reviewable_name"]
    assert_not_nil review["id"]
    assert_not_nil review["rating"]
    assert_not_nil review["comment"]
  end
end
