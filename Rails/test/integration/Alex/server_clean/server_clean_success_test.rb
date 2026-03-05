require "test_helper"

class ServerCleanSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @waiter = users(:waiter_user)
    @client = users(:valid_user)

    # Connexion admin pour créer la table
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    post "/api/tables", params: { table: { number: 701, nb_seats: 4 } }, as: :json
    assert_response :created
    @table_data = JSON.parse(response.body)["data"]
    @table = Table.find(@table_data["id"])
    @initial_token = @table_data["qr_token"]

    delete "/users/sign_out", as: :json
  end

  private

  # Helper : créer une commande en bypassant la validation
  def create_order!(attrs)
    order = Order.new(attrs)
    order.save(validate: false)
    order
  end

  public

  # ══════════════════════════════════════════
  # CLEAN — POST /api/server/orders/:id/clean
  # ══════════════════════════════════════════

  # Test 1: Le serveur peut nettoyer la table après paiement
  test "serveur peut nettoyer la table après paiement" do
    order = create_order!(
      table: @table, client: @client, server: @waiter, nb_people: 2
    )
    order.update_columns(ended_at: 5.minutes.ago)

    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    post "/api/server/orders/#{order.id}/clean", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    @table.reload
    assert_not_nil @table.cleaned_at
    assert_not_equal @initial_token, @table.temporary_code, "Le QR code doit être régénéré"
    assert_not_nil @table.qr_rotated_at
  end

  # Test 2: Clean ferme la commande si pas encore fermée
  test "clean ferme la commande si ended_at est nil" do
    order = create_order!(
      table: @table, client: @client, server: @waiter, nb_people: 2
    )
    assert_nil order.ended_at

    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    post "/api/server/orders/#{order.id}/clean", as: :json

    assert_response :ok
    order.reload
    assert_not_nil order.ended_at
  end

  # Test 3: QR code est régénéré après clean
  test "QR code est différent après clean" do
    order = create_order!(
      table: @table, client: @client, server: @waiter, nb_people: 2
    )
    order.update_columns(ended_at: 5.minutes.ago)

    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    old_token = @table.temporary_code

    post "/api/server/orders/#{order.id}/clean", as: :json

    @table.reload
    assert_not_equal old_token, @table.temporary_code
  end

  # Test 4: Clean avec plusieurs clients sur la même table ferme toutes les commandes
  test "clean ferme toutes les commandes ouvertes de la table" do
    order1 = create_order!(
      table: @table, client: @client, server: @waiter, nb_people: 2
    )
    client2 = users(:inactive_user)
    client2.update_columns(type: "Client", status: "active")
    order2 = create_order!(
      table: @table, client: client2, server: @waiter, nb_people: 1
    )

    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    post "/api/server/orders/#{order1.id}/clean", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]

    order1.reload
    order2.reload
    assert_not_nil order1.ended_at
    assert_not_nil order2.ended_at

    # Le QR est régénéré une seule fois
    @table.reload
    assert_not_equal @initial_token, @table.temporary_code
  end

  # Test 5: La table redevient available après clean
  test "table redevient available après clean" do
    order = create_order!(
      table: @table, client: @client, server: @waiter, nb_people: 2
    )

    post "/users/sign_in", params: {
      user: { email: @waiter.email, password: "password123" }
    }, as: :json

    # Vérifier que la table est occupée
    get "/api/server/tables", as: :json
    json = JSON.parse(response.body)
    table_before = json["data"].find { |t| t["number"] == 701 }
    assert_equal "occupied", table_before["status"]

    # Nettoyer
    post "/api/server/orders/#{order.id}/clean", as: :json
    assert_response :ok

    # Vérifier que la table est disponible
    get "/api/server/tables", as: :json
    json = JSON.parse(response.body)
    table_after = json["data"].find { |t| t["number"] == 701 }
    assert_equal "available", table_after["status"]
  end
end
