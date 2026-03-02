require "test_helper"

class OrderLineUpdateSuccessTest < ActionDispatch::IntegrationTest
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

  # Test 1: Update quantity on sent line returns success
  test "update quantity on sent line returns success" do
    put "/api/orders/#{@order["id"]}/order_lines/#{@line["id"]}",
        params: { order_line: { quantity: 3 } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 3, json["data"].first["quantity"]
  end

  # Test 2: Update note on sent line returns success
  test "update note on sent line returns success" do
    put "/api/orders/#{@order["id"]}/order_lines/#{@line["id"]}",
        params: { order_line: { note: "Extra crispy" } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Extra crispy", json["data"].first["note"]
  end

  # Test 3: Persists changes in DB
  test "update persists quantity change in database" do
    put "/api/orders/#{@order["id"]}/order_lines/#{@line["id"]}",
        params: { order_line: { quantity: 5 } }, as: :json

    updated = OrderLine.find(@line["id"])
    assert_equal 5, updated.quantity
  end
end
