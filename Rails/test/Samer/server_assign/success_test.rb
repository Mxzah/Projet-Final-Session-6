require "test_helper"

class ServerAssignSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @waiter = users(:waiter_user)
    @admin = users(:admin_user)
    @unassigned_order = orders(:unassigned_order)
  end

  # Waiter can assign themselves to an order
  test "waiter assigns self to unassigned order" do
    sign_in @waiter

    post "/api/kitchen/orders/#{@unassigned_order.id}/assign_server", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal @waiter.id, json["data"].first["server_id"]
    assert_not_nil json["data"].first["server_name"]

    # Database state
    @unassigned_order.reload
    assert_equal @waiter.id, @unassigned_order.server_id
  end

  # Admin can assign themselves to an order
  test "admin assigns self to unassigned order" do
    sign_in @admin

    post "/api/kitchen/orders/#{@unassigned_order.id}/assign_server", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal @admin.id, json["data"].first["server_id"]

    # Database state
    @unassigned_order.reload
    assert_equal @admin.id, @unassigned_order.server_id
  end
end
