require "test_helper"

class OrderPayFailTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    @table = Table.create!(number: 97, nb_seats: 10)
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    @order = JSON.parse(response.body)["data"].first
    @item = items(:item_one)
    av = Availability.new(available_type: "Item", available_id: @item.id,
                          start_at: 1.hour.ago, end_at: 1.day.from_now)
    av.save(validate: false)
    post "/api/orders/#{@order["id"]}/order_lines",
         params: { order_line: { orderable_type: "Item", orderable_id: @item.id, quantity: 1 } }, as: :json
  end

  # Test 1: Not authenticated returns success false
  test "pay without authentication returns success false" do
    delete "/users/sign_out", as: :json

    post "/api/orders/#{@order["id"]}/pay", params: { tip: 0 }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 2: Invalid order id returns success false
  test "pay with invalid order id returns success false" do
    post "/api/orders/999999/pay", params: { tip: 0 }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Order not found"
  end

  # Test 3: Lines not all served returns success false
  test "pay when lines are not served returns success false" do
    post "/api/orders/#{@order["id"]}/pay", params: { tip: 0 }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "All items must be 'served' before paying"
  end

  # Test 4: Negative tip returns success false (lines marked served to bypass that check)
  test "pay with negative tip returns success false" do
    OrderLine.where(order_id: @order["id"]).update_all(status: "served")

    post "/api/orders/#{@order["id"]}/pay", params: { tip: -1 }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Tip cannot be negative"
  end

  # Test 5: Tip over 999.99 returns success false (lines marked served to bypass that check)
  test "pay with tip over 999.99 returns success false" do
    OrderLine.where(order_id: @order["id"]).update_all(status: "served")

    post "/api/orders/#{@order["id"]}/pay", params: { tip: 1000.00 }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Tip cannot exceed 999.99"
  end
end
