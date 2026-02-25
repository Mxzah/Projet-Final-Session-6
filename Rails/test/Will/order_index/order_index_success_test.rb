require "test_helper"

class OrderIndexSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    @table = Table.create!(number: 97, nb_seats: 10)
  end

  # Test 1: Returns 200 and success true when no orders
  test "index returns 200 success true and empty data when no orders" do
    get "/api/orders", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 200, json["code"]
    assert_equal [], json["data"]
    assert_equal [], json["errors"]
  end

  # Test 2: data and errors are arrays
  test "index returns data and errors as arrays" do
    get "/api/orders", as: :json

    json = JSON.parse(response.body)
    assert_instance_of Array, json["data"]
    assert_instance_of Array, json["errors"]
  end

  # Test 3: Returns orders belonging to the current client
  test "index returns orders for the connected client" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json

    get "/api/orders", as: :json

    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1
    json["data"].each { |o| assert_equal @user.id, o["client_id"] }
  end

  # Test 4: Returns all expected fields in each order
  test "index returns all expected fields in each order" do
    post "/api/orders", params: { order: { nb_people: 3, table_id: @table.id, note: "Test note" } }, as: :json

    get "/api/orders", as: :json

    json = JSON.parse(response.body)
    order = json["data"].first
    assert order.key?("id")
    assert order.key?("nb_people")
    assert order.key?("note")
    assert order.key?("table_id")
    assert order.key?("table_number")
    assert order.key?("client_id")
    assert order.key?("order_lines")
    assert order.key?("created_at")
    assert order.key?("ended_at")
    assert order.key?("total")
    assert order.key?("tip")
  end

  # Test 5: Does not return orders from another client
  test "index does not return orders from another client" do
    other_table = Table.create!(number: 98, nb_seats: 4)
    other_client = Client.create!(email: "other@test.ca", password: "password123",
                                  password_confirmation: "password123",
                                  first_name: "Other", last_name: "User", status: "active")
    Order.create!(nb_people: 1, table: other_table, client: other_client)

    get "/api/orders", as: :json

    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  # Test 6: table_number matches the assigned table
  test "index returns correct table number in order" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json

    get "/api/orders", as: :json

    json = JSON.parse(response.body)
    order = json["data"].first
    assert_equal 97, order["table_number"]
  end
end
