require "test_helper"

class OrderPaySuccessTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    @table = Table.create!(number: 97, nb_seats: 10)
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    @order = JSON.parse(response.body)["data"].first
  end

  # Test 1: Pay order with no lines (vacuously all served) and no tip
  test "pay order with no lines returns success and sets ended_at" do
    post "/api/orders/#{@order["id"]}/pay", params: { tip: 0 }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not_nil json["data"].first["ended_at"]
    assert_equal 0.0, json["data"].first["tip"]
  end

  # Test 2: Pay with tip
  test "pay with tip returns success and correct tip value" do
    post "/api/orders/#{@order["id"]}/pay", params: { tip: 5.00 }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 5.0, json["data"].first["tip"]
  end

  # Test 3: Sets ended_at in DB
  test "pay sets ended_at in database" do
    post "/api/orders/#{@order["id"]}/pay", params: { tip: 0 }, as: :json

    order = Order.unscoped.find(@order["id"])
    assert_not_nil order.ended_at
  end
end
