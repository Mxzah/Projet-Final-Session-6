require "test_helper"

class OrderShowSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    @table = Table.create!(number: 97, nb_seats: 10)
    post "/api/orders", params: { order: { nb_people: 4, table_id: @table.id, note: "No gluten" } }, as: :json
    @order = JSON.parse(response.body)["data"].first
  end

  # Test 1: Returns 200 and success true
  test "show returns 200 and success true" do
    get "/api/orders/#{@order["id"]}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
    assert_equal 1, json["data"].length
  end

  # Test 2: Returns correct order data
  test "show returns correct order data" do
    get "/api/orders/#{@order["id"]}", as: :json

    json = JSON.parse(response.body)
    order = json["data"].first
    assert_equal @order["id"], order["id"]
    assert_equal 4, order["nb_people"]
    assert_equal "No gluten", order["note"]
    assert_equal @table.id, order["table_id"]
    assert_equal 97, order["table_number"]
    assert_equal @user.id, order["client_id"]
  end

  

  # Test 4: order_lines is empty when order has no lines
  test "show returns empty order_lines when no lines" do
    get "/api/orders/#{@order["id"]}", as: :json

    json = JSON.parse(response.body)
    assert_equal [], json["data"].first["order_lines"]
    assert_equal 0.0, json["data"].first["total"]
  end
end
