require "test_helper"

class OrderCreateSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    @table = Table.create!(number: 97, nb_seats: 10)
  end

  # Test 1: Create with required fields returns success
  test "create with valid nb_people and table_id returns success" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
    assert_equal 2, json["data"].first["nb_people"]
    assert_equal @table.id, json["data"].first["table_id"]
    assert_equal @user.id, json["data"].first["client_id"]
  end

  # Test 2: Create with optional note
  test "create with note returns success and note in response" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id, note: "Allergie aux noix" } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Allergie aux noix", json["data"].first["note"]
  end

  # Test 3: Saves order in DB
  test "create saves order in database" do
    assert_difference "Order.count", 1 do
      post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    end
  end

  # Test 4: Returns all expected fields
  test "create returns all expected fields" do
    post "/api/orders", params: { order: { nb_people: 3, table_id: @table.id } }, as: :json

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
  end

  # Test 5: New order has ended_at nil and empty lines
  test "create returns order with ended_at nil and empty order_lines" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json

    json = JSON.parse(response.body)
    order = json["data"].first
    assert_nil order["ended_at"]
    assert_equal [], order["order_lines"]
    assert_equal 0.0, order["total"]
  end
end
