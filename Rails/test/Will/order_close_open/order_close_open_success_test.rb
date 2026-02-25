require "test_helper"

class OrderCloseOpenSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    @table = Table.create!(number: 97, nb_seats: 10)
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    @order = JSON.parse(response.body)["data"].first
  end

  # Test 1: Closes open orders and returns success
  test "close_open closes open orders and returns success true" do
    post "/api/orders/close_open", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 200, json["code"]
    assert_equal [], json["data"]
    assert_equal [], json["errors"]
  end

  # Test 2: Sets ended_at in DB
  test "close_open sets ended_at on open orders in database" do
    post "/api/orders/close_open", as: :json

    order = Order.unscoped.find(@order["id"])
    assert_not_nil order.ended_at
  end

  # Test 3: Returns success true even when no open orders
  test "close_open returns success true when no open orders" do
    post "/api/orders/close_open", as: :json
    post "/api/orders/close_open", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
  end
end
