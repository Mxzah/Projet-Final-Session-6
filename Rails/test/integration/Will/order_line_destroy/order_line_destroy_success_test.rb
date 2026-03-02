require "test_helper"

class OrderLineDestroySuccessTest < ActionDispatch::IntegrationTest
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

  # Test 1: Destroy sent line returns success
  test "destroy sent line returns success and empty data" do
    delete "/api/orders/#{@order["id"]}/order_lines/#{@line["id"]}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal [], json["data"]
    assert_equal [], json["errors"]
  end

  # Test 2: Line is removed from DB
  test "destroy removes line from database" do
    line_id = @line["id"]
    delete "/api/orders/#{@order["id"]}/order_lines/#{line_id}", as: :json

    assert_nil OrderLine.find_by(id: line_id)
  end
end
