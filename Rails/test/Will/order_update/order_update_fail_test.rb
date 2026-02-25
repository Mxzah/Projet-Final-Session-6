require "test_helper"

class OrderUpdateFailTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    @table = Table.create!(number: 97, nb_seats: 10)
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    @order = JSON.parse(response.body)["data"].first
  end

  # Test 1: Not authenticated returns success false
  test "update without authentication returns success false" do
    delete "/users/sign_out", as: :json

    put "/api/orders/#{@order["id"]}", params: { order: { note: "hacked" } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 2: Invalid order id returns success false
  test "update with invalid id returns success false" do
    put "/api/orders/999999", params: { order: { note: "test" } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_equal [], json["data"]
    assert_includes json["errors"], "Order not found"
  end

  # Test 3: Note over 255 chars returns success false
  test "update with note over 255 chars returns success false" do
    put "/api/orders/#{@order["id"]}", params: { order: { note: "A" * 256 } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 4: Another client order returns success false
  test "update another client order returns success false" do
    other_table = Table.create!(number: 98, nb_seats: 4)
    other_client = Client.create!(email: "other@test.ca", password: "password123",
                                  password_confirmation: "password123",
                                  first_name: "Other", last_name: "User", status: "active")
    other_order = Order.create!(nb_people: 1, table: other_table, client: other_client)

    put "/api/orders/#{other_order.id}", params: { order: { note: "hacked" } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Order not found"
  end
end
