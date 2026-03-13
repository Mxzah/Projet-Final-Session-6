# frozen_string_literal: true

require "test_helper"

class ComboItemIndexFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @combo = combos(:combo_one)
    @item1 = items(:item_one)

    # Créer un combo item via admin
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json

    post "/api/combo_items", params: {
      combo_item: { combo_id: @combo.id, item_id: @item1.id, quantity: 2 }
    }, as: :json

    @combo_item = JSON.parse(response.body)["data"]
  end

  # ══════════════════════════════════════════
  # INCLUDE_DELETED — AUTORISATION
  # ══════════════════════════════════════════

  # Test 1: Client avec include_deleted ne voit pas les items supprimés
  test "client avec include_deleted ne voit pas les items supprimés" do
    # Supprimer le combo item
    delete "/api/combo_items/#{@combo_item['id']}", as: :json
    assert_response :ok

    # Se connecter comme client
    delete "/users/sign_out", as: :json
    client = users(:valid_user)
    post "/users/sign_in", params: {
      user: { email: client.email, password: "password123" }
    }, as: :json

    get "/api/combo_items", params: { include_deleted: "true" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    # Le combo item supprimé ne devrait pas apparaître pour un client
    ids = json["data"].map { |ci| ci["id"] }
    assert_not_includes ids, @combo_item["id"]
  end

  # Test 2: Non connecté avec include_deleted ne voit pas les items supprimés
  test "non connecté avec include_deleted ne voit pas les items supprimés" do
    # Supprimer le combo item
    delete "/api/combo_items/#{@combo_item['id']}", as: :json
    assert_response :ok

    # Se déconnecter
    delete "/users/sign_out", as: :json

    get "/api/combo_items", params: { include_deleted: "true" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    ids = json["data"].map { |ci| ci["id"] }
    assert_not_includes ids, @combo_item["id"]
  end

  # Test 3: Admin avec include_deleted voit les items supprimés
  test "admin avec include_deleted voit les items supprimés" do
    # Supprimer le combo item
    delete "/api/combo_items/#{@combo_item['id']}", as: :json
    assert_response :ok

    get "/api/combo_items", params: { include_deleted: "true" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    ids = json["data"].map { |ci| ci["id"] }
    assert_includes ids, @combo_item["id"]
  end
end
