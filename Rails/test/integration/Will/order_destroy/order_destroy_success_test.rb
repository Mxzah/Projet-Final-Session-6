require "test_helper"

class OrderDestroySuccessTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    @table = Table.create!(number: 97, nb_seats: 10)
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    @order = JSON.parse(response.body)["data"].first
  end

  # Test 1: Destroy own order returns success
  test "destroy own order returns success and empty data" do
    delete "/api/orders/#{@order["id"]}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal [], json["data"]
    assert_equal [], json["errors"]
  end

  # Test 2: Order is removed from DB
  test "destroy removes order from database" do
    order_id = @order["id"]
    delete "/api/orders/#{order_id}", as: :json

    assert_nil Order.unscoped.find_by(id: order_id)
  end
end
