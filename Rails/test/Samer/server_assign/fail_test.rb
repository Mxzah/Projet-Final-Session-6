require "test_helper"

class ServerAssignFailTest < ActionDispatch::IntegrationTest
  setup do
    @cook = users(:cook_user)
    @client = users(:valid_user)
    @waiter = users(:waiter_user)
    @open_order = orders(:open_order)
    @closed_order = orders(:closed_order)
    @unassigned_order = orders(:unassigned_order)
  end

  # Cook cannot assign server
  test "cook cannot assign server" do
    sign_in @cook

    post "/api/kitchen/orders/#{@unassigned_order.id}/assign_server", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
    assert_includes json["errors"], "Unauthorized"

    # Database state: unchanged
    @unassigned_order.reload
    assert_nil @unassigned_order.server_id
  end

  # Client cannot assign server (not kitchen staff)
  test "client cannot access kitchen endpoint" do
    sign_in @client

    post "/api/kitchen/orders/#{@unassigned_order.id}/assign_server", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
  end

  # Order already has a server
  test "cannot assign to order that already has a server" do
    sign_in @waiter

    post "/api/kitchen/orders/#{@open_order.id}/assign_server", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
    assert_includes json["errors"], "Order already has a server assigned"
  end

  # Order is already closed
  test "cannot assign to closed order" do
    sign_in @waiter

    post "/api/kitchen/orders/#{@closed_order.id}/assign_server", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
    assert_includes json["errors"], "Order is already closed"
  end

  # Order not found
  test "assign to non-existent order returns error" do
    sign_in @waiter

    post "/api/kitchen/orders/999999/assign_server", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert_not json["success"]
    assert_includes json["errors"], "Order not found"
  end
end
