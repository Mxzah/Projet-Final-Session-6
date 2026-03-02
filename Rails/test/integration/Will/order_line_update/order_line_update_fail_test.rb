require "test_helper"

class OrderLineUpdateFailTest < ActionDispatch::IntegrationTest
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
    @line = JSON.parse(response.body)["data"].first
  end

  # Test 1: Not authenticated returns success false
  test "update without authentication returns success false" do
    delete "/users/sign_out", as: :json

    put "/api/orders/#{@order["id"]}/order_lines/#{@line["id"]}",
        params: { order_line: { quantity: 3 } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 2: Line not found returns success false
  test "update with invalid line id returns success false" do
    put "/api/orders/#{@order["id"]}/order_lines/999999",
        params: { order_line: { quantity: 2 } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Order line not found"
  end

  # Test 3: Cannot modify line with non-sent status
  test "update line with in_preparation status returns success false" do
    line = OrderLine.new(order_id: @order["id"], orderable_type: "Item", orderable_id: @item.id,
                         quantity: 1, unit_price: 10.0, status: "in_preparation")
    line.save(validate: false)

    put "/api/orders/#{@order["id"]}/order_lines/#{line.id}",
        params: { order_line: { quantity: 3 } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 4: quantity = 0 is invalid
  test "update with quantity 0 returns success false" do
    put "/api/orders/#{@order["id"]}/order_lines/#{@line["id"]}",
        params: { order_line: { quantity: 0 } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 5: quantity = 51 exceeds maximum
  test "update with quantity 51 returns success false" do
    put "/api/orders/#{@order["id"]}/order_lines/#{@line["id"]}",
        params: { order_line: { quantity: 51 } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
