require "test_helper"

class OrderLineDestroyFailTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    @table = Table.create!(number: 97, nb_seats: 10)
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    @order = JSON.parse(response.body)["data"].first
    @item = items(:item_one)
  end

  # Test 1: Not authenticated returns success false
  test "destroy without authentication returns success false" do
    delete "/users/sign_out", as: :json

    delete "/api/orders/#{@order["id"]}/order_lines/999999", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 2: Line not found returns success false
  test "destroy with invalid line id returns success false" do
    delete "/api/orders/#{@order["id"]}/order_lines/999999", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Order line not found"
  end

  # Test 3: Cannot delete line with non-sent status
  test "destroy line with in_preparation status returns success false" do
    line = OrderLine.new(order_id: @order["id"], orderable_type: "Item", orderable_id: @item.id,
                         quantity: 1, unit_price: 10.0, status: "in_preparation")
    line.save(validate: false)

    delete "/api/orders/#{@order["id"]}/order_lines/#{line.id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end
end
