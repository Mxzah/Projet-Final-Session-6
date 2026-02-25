require "test_helper"

class OrderLineCreateSuccessTest < ActionDispatch::IntegrationTest
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
  end

  # Test 1: Create line with valid params returns success
  test "create order line returns success with price and status sent" do
    post "/api/orders/#{@order["id"]}/order_lines",
         params: { order_line: { orderable_type: "Item", orderable_id: @item.id, quantity: 2 } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 2, json["data"].first["quantity"]
    assert_equal "sent", json["data"].first["status"]
    assert_equal @item.price.to_f, json["data"].first["unit_price"]
  end

  # Test 2: Create line with note
  test "create order line with note returns success and note" do
    post "/api/orders/#{@order["id"]}/order_lines",
         params: { order_line: { orderable_type: "Item", orderable_id: @item.id, quantity: 1, note: "No sauce" } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "No sauce", json["data"].first["note"]
  end

  # Test 3: Saves to DB
  test "create saves order line in database" do
    assert_difference "OrderLine.count", 1 do
      post "/api/orders/#{@order["id"]}/order_lines",
           params: { order_line: { orderable_type: "Item", orderable_id: @item.id, quantity: 1 } }, as: :json
    end
  end

 
end
