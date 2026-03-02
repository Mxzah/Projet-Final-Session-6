require "test_helper"

class OrderCreateFailTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    @table = Table.create!(number: 97, nb_seats: 4)
  end

  # Test 1: Not authenticated returns success false
  test "create without authentication returns success false" do
    delete "/users/sign_out", as: :json

    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 2: Missing nb_people returns success false
  test "create without nb_people returns success false" do
    post "/api/orders", params: { order: { table_id: @table.id } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_equal [], json["data"]
    assert json["errors"].any?
  end

  # Test 3: nb_people = 0 is invalid
  test "create with nb_people 0 returns success false" do
    post "/api/orders", params: { order: { nb_people: 0, table_id: @table.id } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 4: nb_people = 21 exceeds maximum
  test "create with nb_people 21 returns success false" do
    post "/api/orders", params: { order: { nb_people: 21, table_id: @table.id } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 5: Note over 255 chars returns success false
  test "create with note over 255 chars returns success false" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id, note: "A" * 256 } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 6: nb_people exceeds table capacity (table has 4 seats)
  test "create with nb_people over table capacity returns success false" do
    post "/api/orders", params: { order: { nb_people: 5, table_id: @table.id } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 7: Client already has an open order
  test "create when client already has open order returns success false" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    assert JSON.parse(response.body)["success"]

    table2 = Table.create!(number: 98, nb_seats: 4)
    post "/api/orders", params: { order: { nb_people: 2, table_id: table2.id } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 8: Missing table_id returns success false
  test "create without table_id returns success false" do
    post "/api/orders", params: { order: { nb_people: 2 } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 9: Invalid create does not save to DB
  test "create with invalid data does not save to database" do
    assert_no_difference "Order.count" do
      post "/api/orders", params: { order: { nb_people: 0, table_id: @table.id } }, as: :json
    end
  end
end
