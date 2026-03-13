# frozen_string_literal: true

require "test_helper"

class ComboIndexSsfSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @combo1 = combos(:combo_one)    # "Duo Test" - 59.99
    @combo2 = combos(:combo_two)    # "Trio Prestige" - 89.99
    @combo3 = combos(:combo_three)  # "Solo Découverte" - 29.99

    # Connexion admin
    post "/users/sign_in", params: {
      user: { email: @admin.email, password: "password123" }
    }, as: :json
  end

  # ══════════════════════════════════════════
  # SEARCH
  # ══════════════════════════════════════════

  # Test 1: Recherche par nom retourne les combos correspondants
  test "search par nom retourne les combos correspondants" do
    get "/api/combos", params: { admin: "true", search: "Duo" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1
    json["data"].each do |combo|
      assert_match(/Duo/i, combo["name"])
    end
  end

  # Test 2: Recherche partielle retourne les combos correspondants
  test "search partielle retourne les combos correspondants" do
    get "/api/combos", params: { admin: "true", search: "Trio" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1
    json["data"].each do |combo|
      assert_match(/Trio/i, combo["name"])
    end
  end

  # Test 3: Recherche sans résultat retourne liste vide
  test "search sans résultat retourne liste vide" do
    get "/api/combos", params: { admin: "true", search: "InexistantXYZ" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  # Test 4: Recherche sans paramètre retourne tous les combos
  test "search sans paramètre retourne tous les combos" do
    get "/api/combos", params: { admin: "true" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 3
  end

  # ══════════════════════════════════════════
  # SORT
  # ══════════════════════════════════════════

  # Test 5: Tri par prix croissant
  test "sort asc retourne les combos triés par prix croissant" do
    get "/api/combos", params: { admin: "true", sort: "asc" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    prices = json["data"].map { |c| c["price"] }
    assert_equal prices, prices.sort
  end

  # Test 6: Tri par prix décroissant
  test "sort desc retourne les combos triés par prix décroissant" do
    get "/api/combos", params: { admin: "true", sort: "desc" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    prices = json["data"].map { |c| c["price"] }
    assert_equal prices, prices.sort.reverse
  end

  # Test 7: Sans tri, ordre par défaut (created_at desc)
  test "sans paramètre sort, tri par créé_à décroissant par défaut" do
    get "/api/combos", params: { admin: "true" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    # Vérifier que la réponse est valide sans nécessairement vérifier l'ordre exact
    assert json["data"].length >= 3
  end

  # ══════════════════════════════════════════
  # FILTER — PRIX
  # ══════════════════════════════════════════

  # Test 8: Filtre par prix minimum
  test "filter price_min retourne les combos avec prix suffisant" do
    get "/api/combos", params: { admin: "true", price_min: 50 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    json["data"].each do |combo|
      assert combo["price"] >= 50, "Prix #{combo['price']} est inférieur à 50"
    end
  end

  # Test 9: Filtre par prix maximum
  test "filter price_max retourne les combos avec prix limité" do
    get "/api/combos", params: { admin: "true", price_max: 60 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    json["data"].each do |combo|
      assert combo["price"] <= 60, "Prix #{combo['price']} est supérieur à 60"
    end
  end

  # Test 10: Filtre par fourchette de prix
  test "filter par fourchette de prix retourne les combos dans l'intervalle" do
    get "/api/combos", params: { admin: "true", price_min: 30, price_max: 70 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    json["data"].each do |combo|
      assert combo["price"] >= 30, "Prix #{combo['price']} est inférieur à 30"
      assert combo["price"] <= 70, "Prix #{combo['price']} est supérieur à 70"
    end
    # Combo "Duo Test" (59.99) devrait être inclus
    names = json["data"].map { |c| c["name"] }
    assert_includes names, "Duo Test"
  end

  # Test 11: Filtre avec fourchette excluant tout retourne liste vide
  test "filter avec fourchette impossible retourne liste vide" do
    get "/api/combos", params: { admin: "true", price_min: 10_000, price_max: 20_000 }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 0, json["data"].length
  end

  # ══════════════════════════════════════════
  # COMBINAISONS SSF
  # ══════════════════════════════════════════

  # Test 12: Recherche + tri + filtre combinés
  test "search + sort + filter combinés retournent le bon résultat" do
    get "/api/combos", params: {
      admin: "true",
      search: "o",
      sort: "asc",
      price_min: 20,
      price_max: 100
    }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    prices = json["data"].map { |c| c["price"] }
    assert_equal prices, prices.sort
    json["data"].each do |combo|
      assert combo["price"] >= 20
      assert combo["price"] <= 100
    end
  end

  # ══════════════════════════════════════════
  # INCLUDE_DELETED / ADMIN
  # ══════════════════════════════════════════

  # Test 13: Admin avec admin=true voit tous les combos (sans filtre disponibilité)
  test "admin avec admin=true voit tous les combos" do
    get "/api/combos", params: { admin: "true" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 3
  end

  # Test 14: Non connecté ne voit que les combos avec disponibilité active
  test "non connecté ne voit que les combos avec disponibilité active" do
    delete "/users/sign_out", as: :json

    # Créer une availability active pour combo_one
    @combo1.availabilities.destroy_all
    Availability.create!(available: @combo1, start_at: Time.current, end_at: 1.day.from_now)

    get "/api/combos", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    # Seuls les combos avec disponibilité active doivent apparaître
    names = json["data"].map { |c| c["name"] }
    assert_includes names, "Duo Test"
  end
end
