require "test_helper"

class OrderShowFailTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    @table = Table.create!(number: 97, nb_seats: 10)
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    @order = JSON.parse(response.body)["data"].first
  end

  # Test 1: Not authenticated returns success false
  test "show without authentication returns success false" do
    delete "/users/sign_out", as: :json

    get "/api/orders/#{@order["id"]}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 2: Invalid id raises RecordNotFound
  test "show with invalid id returns success false and nil data" do
    get "/api/orders/999999", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_nil json["data"]
    assert json["errors"].any?
  end

  # Test 3: Another client order returns success false
  test "show with another client order returns success false" do
    other_table = Table.create!(number: 98, nb_seats: 4)
    other_client = Client.create!(email: "other@test.ca", password: "password123",
                                  password_confirmation: "password123",
                                  first_name: "Other", last_name: "User", status: "active")
    other_order = Order.create!(nb_people: 1, table: other_table, client: other_client)

    get "/api/orders/#{other_order.id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_nil json["data"]
  end
end
