require "test_helper"

class OrderLineIndexSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    @table = Table.create!(number: 97, nb_seats: 10)
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    @order = JSON.parse(response.body)["data"].first
  end

  # Test 1: Returns empty lines for an order with no lines
  test "index returns empty array when order has no lines" do
    get "/api/orders/#{@order["id"]}/order_lines", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal [], json["data"]
    assert_equal [], json["errors"]
  end

  # Test 2: Returns order lines when they exist
  test "index returns order lines when lines exist" do
    item = items(:item_one)
    av = Availability.new(available_type: "Item", available_id: item.id,
                          start_at: 1.hour.ago, end_at: 1.day.from_now)
    av.save(validate: false)
    post "/api/orders/#{@order["id"]}/order_lines",
         params: { order_line: { orderable_type: "Item", orderable_id: item.id, quantity: 2 } }, as: :json

    get "/api/orders/#{@order["id"]}/order_lines", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 1, json["data"].length
    assert_equal 2, json["data"].first["quantity"]
  end

  # Test 3: Returns all expected fields in each line
  test "index returns expected fields in each order line" do
    item = items(:item_one)
    av = Availability.new(available_type: "Item", available_id: item.id,
                          start_at: 1.hour.ago, end_at: 1.day.from_now)
    av.save(validate: false)
    post "/api/orders/#{@order["id"]}/order_lines",
         params: { order_line: { orderable_type: "Item", orderable_id: item.id, quantity: 1, note: "Extra" } }, as: :json

    get "/api/orders/#{@order["id"]}/order_lines", as: :json

    json = JSON.parse(response.body)
    line = json["data"].first
    assert line.key?("id")
    assert line.key?("quantity")
    assert line.key?("unit_price")
    assert line.key?("note")
    assert line.key?("status")
    assert line.key?("orderable_type")
    assert line.key?("orderable_id")
    assert line.key?("orderable_name")
    assert line.key?("created_at")
  end
end
