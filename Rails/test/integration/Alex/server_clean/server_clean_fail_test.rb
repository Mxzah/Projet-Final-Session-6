# frozen_string_literal: true

require "test_helper"

class ServerCleanFailTest < ActionDispatch::IntegrationTest
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
  # CLEAN — POST /api/server/orders/:id/clean (échecs)
  # ══════════════════════════════════════════

  # Test 1: Un serveur ne peut pas nettoyer la commande d'un autre
  test "serveur ne peut pas nettoyer la commande d'un autre serveur" do
    order = create_order!(
      table: @table, client: @client, server: @admin, nb_people: 2
    )
    order.update_columns(ended_at: 5.minutes.ago)

    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    post "/api/server/orders/#{order.id}/clean", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 2: Un client ne peut pas nettoyer une table
  test "client ne peut pas nettoyer une table" do
    order = create_order!(
      table: @table, client: @client, server: @waiter, nb_people: 2
    )
    order.update_columns(ended_at: 5.minutes.ago)

    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json

    post "/api/server/orders/#{order.id}/clean", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  # Test 3: Commande inexistante retourne erreur
  test "clean avec commande inexistante retourne erreur" do
    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    post "/api/server/orders/999999/clean", as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
  end
end
