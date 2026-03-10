# frozen_string_literal: true

require "test_helper"

class ItemsStatsFailsTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:entrees)
    @item_one = items(:item_one)       # Tartare, 24.99$, entrees
    @item_two = items(:item_two)       # Bruschetta, 14.50$, entrees
    @client = users(:valid_user)

    # Attacher une image aux fixtures
    [@item_one, @item_two].each do |item|
      item.image.attach(
        io: File.open(Rails.root.join("test/fixtures/files/test.jpg")),
        filename: "test.jpg", content_type: "image/jpeg"
      )
    end

    sign_in users(:admin_user)
  end

  # ── Contrôle d'accès ──

  test "stats avec un compte client retourne success false" do
    sign_out :user
    sign_in @client

    get "/api/items/stats", as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_includes json["errors"], I18n.t("controllers.admin.access_restricted")
  end

  test "stats sans authentification retourne success false" do
    sign_out :user

    get "/api/items/stats", as: :json

    json = JSON.parse(response.body)

    assert_not json["success"]
  end

  # ── Validation des dates ──

  test "stats avec format de date début invalide retourne success false" do
    get "/api/items/stats", params: { start_date: "invalid" }
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_includes json["errors"], I18n.t("controllers.stats.invalid_start_date")
  end

  test "stats avec format de date fin invalide retourne success false" do
    get "/api/items/stats", params: { end_date: "2026-13-99" }
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_includes json["errors"], I18n.t("controllers.stats.invalid_end_date")
  end

  test "stats avec date fin avant date début retourne success false" do
    get "/api/items/stats", params: {
      start_date: "2026-03-10",
      end_date: "2026-03-01"
    }
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_includes json["errors"], I18n.t("controllers.stats.end_before_start")
  end
end
