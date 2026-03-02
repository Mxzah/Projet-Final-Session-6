require "test_helper"

class OrderLineCreateFailTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    @table = Table.create!(number: 97, nb_seats: 10)
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    @order = JSON.parse(response.body)["data"].first
    @item = items(:item_one)
  end

  # Test 1: Not authenticated returns success false
  test "create without authentication returns success false" do
    delete "/users/sign_out", as: :json

    post "/api/orders/#{@order["id"]}/order_lines",
         params: { order_line: { orderable_type: "Item", orderable_id: @item.id, quantity: 1 } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 2: quantity = 0 is invalid
  test "create with quantity 0 returns success false" do
    post "/api/orders/#{@order["id"]}/order_lines",
         params: { order_line: { orderable_type: "Item", orderable_id: @item.id, quantity: 0 } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 3: quantity = 51 exceeds maximum
  test "create with quantity 51 returns success false" do
    post "/api/orders/#{@order["id"]}/order_lines",
         params: { order_line: { orderable_type: "Item", orderable_id: @item.id, quantity: 51 } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 4: Missing orderable_type returns success false
  test "create without orderable_type returns success false" do
    post "/api/orders/#{@order["id"]}/order_lines",
         params: { order_line: { orderable_id: @item.id, quantity: 1 } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 5: Item not currently available returns success false
  test "create with unavailable item returns success false" do
    post "/api/orders/#{@order["id"]}/order_lines",
         params: { order_line: { orderable_type: "Item", orderable_id: @item.id, quantity: 1 } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 6: Invalid create does not save to DB
  test "create with invalid data does not save to database" do
    assert_no_difference "OrderLine.count" do
      post "/api/orders/#{@order["id"]}/order_lines",
           params: { order_line: { orderable_type: "Item", orderable_id: @item.id, quantity: 0 } }, as: :json
    end
  end
end
