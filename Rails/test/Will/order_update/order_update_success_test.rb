require "test_helper"

class OrderUpdateSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid_user)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    @table = Table.create!(number: 97, nb_seats: 10)
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    @order = JSON.parse(response.body)["data"].first
  end

  # Test 1: Update note returns success and updated note
  test "update note returns success and updated note" do
    put "/api/orders/#{@order["id"]}", params: { order: { note: "Extra bread please" } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Extra bread please", json["data"].first["note"]
  end

  

  # Test 2: Note is persisted in the database
  test "update persists note in database" do
    put "/api/orders/#{@order["id"]}", params: { order: { note: "Vegetarian menu" } }, as: :json

    updated = Order.find(@order["id"])
    assert_equal "Vegetarian menu", updated.note
  end
end
