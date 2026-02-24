require "test_helper"

class TableQrRotationTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @waiter = users(:waiter_user)
    @client = users(:valid_user)

    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    post "/api/tables", params: {
      table: { number: 321, nb_seats: 4 }
    }, as: :json

    assert_response :created
    @table_data = JSON.parse(response.body)["data"]
    @table_id = @table_data["id"]
    @initial_token = @table_data["qr_token"]
  end

  test "mark_cleaned rotates qr token after closed order" do
    table = Table.find(@table_id)

    Order.create!(
      table: table,
      client: @client,
      server: @waiter,
      nb_people: 2,
      ended_at: 5.minutes.ago
    )

    patch "/api/tables/#{@table_id}/mark_cleaned", params: {
      cleaned_at: (table.created_at + 2.seconds).iso8601
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not_equal @initial_token, json.dig("data", "qr_token")

    table.reload
    assert_equal json.dig("data", "qr_token"), table.temporary_code
    assert_not_nil table.qr_rotated_at
  end

  test "mark_cleaned does not rotate qr token while table has open order" do
    table = Table.find(@table_id)

    Order.create!(
      table: table,
      client: @client,
      server: @waiter,
      nb_people: 3,
      ended_at: nil
    )

    patch "/api/tables/#{@table_id}/mark_cleaned", params: {
      cleaned_at: (table.created_at + 2.seconds).iso8601
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal @initial_token, json.dig("data", "qr_token")
  end

  test "client cannot call mark_cleaned" do
    delete "/users/sign_out", as: :json
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    patch "/api/tables/#{@table_id}/mark_cleaned", params: {
      cleaned_at: Time.current.iso8601
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["errors"], "Access restricted to cleaning staff"
  end
end
