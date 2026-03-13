# frozen_string_literal: true

require "test_helper"

class ComboIndexSsfFailTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)

    # Connexion admin
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json
  end

  # ══════════════════════════════════════════
  # SEARCH — Cas limites
  # ══════════════════════════════════════════

  # Test 1: Recherche avec texte qui ne correspond à aucun combo retourne liste vide
  test "search avec texte inexistant retourne liste vide" do
    get "/api/combos", params: { admin: "true", search: "ZZZInexistant999" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  # Test 2: Recherche avec texte très long retourne liste vide
  test "search avec texte très long retourne liste vide" do
    get "/api/combos", params: { admin: "true", search: "a" * 500 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  # ══════════════════════════════════════════
  # SORT — Cas limites
  # ══════════════════════════════════════════

  # Test 3: Sort avec valeur invalide utilise le tri par défaut
  test "sort avec valeur invalide utilise le tri par défaut" do
    get "/api/combos", params: { admin: "true", sort: "invalide" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    # Ne plante pas, utilise l'ordre par défaut
    assert json["data"].length >= 3
  end

  # ══════════════════════════════════════════
  # FILTER — Cas limites
  # ══════════════════════════════════════════

  # Test 4: Filter avec price_min > price_max retourne liste vide
  test "filter avec min supérieur à max retourne liste vide" do
    get "/api/combos", params: { admin: "true", price_min: 100, price_max: 10 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  # Test 5: Filter avec price_min très élevé retourne liste vide
  test "filter avec price_min très élevé retourne liste vide" do
    get "/api/combos", params: { admin: "true", price_min: 99999 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  # ══════════════════════════════════════════
  # INCLUDE_DELETED — AUTORISATION
  # ══════════════════════════════════════════

  # Test 6: Client avec include_deleted ne voit pas les combos supprimés
  test "client avec include_deleted ne voit pas les combos supprimés" do
    delete "/users/sign_out", as: :json
    client = users(:valid_user)
    post "/users/sign_in", params: {
      user: { email: client.email, password: "password123" }
    }, as: :json

    # Créer une availability pour qu'au moins un combo soit visible
    combos(:combo_one).availabilities.destroy_all
    Availability.create!(available: combos(:combo_one), start_at: Time.current, end_at: 1.day.from_now)

    get "/api/combos", params: { include_deleted: "true" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    # Le client ne doit pas voir les combos supprimés
    json["data"].each do |combo|
      assert_nil combo["deleted_at"], "Le client ne devrait pas voir un combo supprimé"
    end
  end
end
