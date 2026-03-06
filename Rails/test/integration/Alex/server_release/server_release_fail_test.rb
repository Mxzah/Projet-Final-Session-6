# frozen_string_literal: true

require "test_helper"

class ServerReleaseFailTest < ActionDispatch::IntegrationTest
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
  # RELEASE — POST /api/server/orders/:id/release (échecs)
  # ══════════════════════════════════════════

  # Test 1: Un serveur ne peut pas libérer la commande d'un autre serveur
  test "serveur ne peut pas libérer une commande assignée à un autre" do
    order = create_order!(
      table: @table, client: @client, server: @admin, nb_people: 2
    )

    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    post "/api/server/orders/#{order.id}/release", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 2: Un client ne peut pas libérer une commande
  test "client ne peut pas libérer une commande" do
    order = create_order!(
      table: @table, client: @client, server: @waiter, nb_people: 2
    )

    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    post "/api/server/orders/#{order.id}/release", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 3: Release avec commande inexistante retourne erreur
  test "release avec commande inexistante retourne erreur" do
    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    post "/api/server/orders/999999/release", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
