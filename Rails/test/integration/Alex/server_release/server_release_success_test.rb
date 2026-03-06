# frozen_string_literal: true

require "test_helper"

class ServerReleaseSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @waiter = users(:waiter_user)
    @client = users(:valid_user)

    # Connexion admin pour créer la table
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    post "/api/tables", params: { table: { number: 701, nb_seats: 4 } }, as: :json
    assert_response :ok
    @table_data = JSON.parse(response.body)["data"]
    @table = Table.find(@table_data["id"])

    delete "/users/sign_out", as: :json
  end

  private

  # Helper : créer une commande en bypassant la validation
  def create_order!(attrs)
    order = Order.new(attrs)
    order.save(validate: false)
    order
  end

  # ══════════════════════════════════════════
  # RELEASE — POST /api/server/orders/:id/release
  # ══════════════════════════════════════════

  # Test 1: Le serveur peut libérer sa commande
  test "serveur peut libérer sa commande" do
    order = create_order!(
      table: @table, client: @client, server: @waiter, nb_people: 2
    )

    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    post "/api/server/orders/#{order.id}/release", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    order.reload
    assert_not_nil order.ended_at
    assert order.server_released
  end

  # Test 2: Release ferme TOUTES les commandes de la table pour ce serveur
  test "release ferme toutes les commandes ouvertes de la table" do
    order1 = create_order!(
      table: @table, client: @client, server: @waiter, nb_people: 2
    )
    # Deuxième client sur la même table
    client2 = users(:inactive_user)
    client2.update_columns(type: "Client", status: "active")
    order2 = create_order!(
      table: @table, client: client2, server: @waiter, nb_people: 1
    )

    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    post "/api/server/orders/#{order1.id}/release", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    order1.reload
    order2.reload
    assert_not_nil order1.ended_at
    assert_not_nil order2.ended_at
    assert order1.server_released
    assert order2.server_released
  end
end
