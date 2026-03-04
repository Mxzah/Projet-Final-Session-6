require "test_helper"

class VibeSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @vibe  = vibes(:vibe_zen)
    @archived_vibe = vibes(:vibe_archived)

    post "/users/sign_in", params: { user: { email: @admin.email, password: "password123" } }, as: :json
  end

  # ══════════════════════════════════════════
  # INDEX — GET /api/vibes
  # ══════════════════════════════════════════

  test "index retourne 200 et success true" do
    get "/api/vibes", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
    assert_equal [],          json["errors"]
  end

  test "index retourne les vibes avec les champs attendus" do
    get "/api/vibes", as: :json

    vibe = JSON.parse(response.body)["data"].find { |v| v["id"] == @vibe.id }
    assert_not_nil vibe
    assert vibe.key?("id")
    assert vibe.key?("name")
    assert vibe.key?("color")
    assert vibe.key?("deleted_at")
    assert vibe.key?("image")
    assert vibe.key?("in_use")
  end

  test "index retourne le champ image comme hash ou nil" do
    get "/api/vibes", as: :json

    vibe = JSON.parse(response.body)["data"].find { |v| v["id"] == @vibe.id }
    # Sans image attachée, image doit être nil
    assert_nil vibe["image"]
  end

  test "index retourne le nom et la couleur corrects" do
    get "/api/vibes", as: :json

    vibe = JSON.parse(response.body)["data"].find { |v| v["id"] == @vibe.id }
    assert_equal "Zen",      vibe["name"]
    assert_equal "#4CAF50",  vibe["color"]
  end

  test "index admin inclut les vibes archivées" do
    get "/api/vibes", as: :json

    ids = JSON.parse(response.body)["data"].map { |v| v["id"] }
    assert_includes ids, @archived_vibe.id
  end

  test "index client ne voit pas les vibes archivées" do
    delete "/users/sign_out", as: :json
    post "/users/sign_in", params: { user: { email: users(:valid_user).email, password: "password123" } }, as: :json

    get "/api/vibes", as: :json

    ids = JSON.parse(response.body)["data"].map { |v| v["id"] }
    assert_not_includes ids, @archived_vibe.id
  end

  test "index est accessible sans authentification" do
    delete "/users/sign_out", as: :json

    get "/api/vibes", as: :json

    assert_response :ok
    assert JSON.parse(response.body)["success"]
  end

  # ══════════════════════════════════════════
  # CREATE — POST /api/vibes
  # ══════════════════════════════════════════

  test "create retourne 200 et success true" do
    post "/api/vibes", params: { vibe: { name: "Nordique", color: "#1E88E5" } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Hash, json["data"]
    assert_equal [],         json["errors"]
  end

  test "create retourne les données correctes" do
    post "/api/vibes", params: { vibe: { name: "Tropical", color: "#FFA726" } }, as: :json

    vibe = JSON.parse(response.body)["data"]
    assert_equal "Tropical", vibe["name"]
    assert_equal "#FFA726",  vibe["color"]
    assert_nil               vibe["deleted_at"]
  end

  test "create sauvegarde la vibe en base de données" do
    assert_difference "Vibe.count", 1 do
      post "/api/vibes", params: { vibe: { name: "Boréale", color: "#7E57C2" } }, as: :json
    end
  end

  # ══════════════════════════════════════════
  # UPDATE — PUT /api/vibes/:id
  # ══════════════════════════════════════════

  test "update retourne 200 et success true" do
    put "/api/vibes/#{@vibe.id}", params: { vibe: { name: "Zen Modifié" } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Hash, json["data"]
  end

  test "update retourne les données mises à jour" do
    put "/api/vibes/#{@vibe.id}", params: { vibe: { name: "Nouveau Nom", color: "#000000" } }, as: :json

    vibe = JSON.parse(response.body)["data"]
    assert_equal "Nouveau Nom", vibe["name"]
    assert_equal "#000000",     vibe["color"]
  end

  test "update persiste les changements en base de données" do
    put "/api/vibes/#{@vibe.id}", params: { vibe: { name: "Zen Persisté" } }, as: :json

    assert_equal "Zen Persisté", Vibe.find(@vibe.id).name
  end

  # ══════════════════════════════════════════
  # DESTROY — DELETE /api/vibes/:id
  # ══════════════════════════════════════════

  test "destroy supprime complètement une vibe sans commandes" do
    post "/api/vibes", params: { vibe: { name: "VibeASupprimer", color: "#111111" } }, as: :json
    vibe_id = JSON.parse(response.body)["data"]["id"]

    assert_difference "Vibe.unscoped.count", -1 do
      delete "/api/vibes/#{vibe_id}", as: :json
    end

    assert_response :ok
    assert JSON.parse(response.body)["success"]
  end

  test "destroy soft-delete une vibe qui a des commandes" do
    post "/api/vibes", params: { vibe: { name: "VibeEnUtilisation", color: "#222222" } }, as: :json
    vibe_id = JSON.parse(response.body)["data"]["id"]

    # Créer un ordre lié à cette vibe
    OrderLine.joins(:order).where(orders: { client_id: users(:valid_user).id }).delete_all
    Order.where(client_id: users(:valid_user).id).delete_all
    Order.create!(table: tables(:table_one), client: users(:valid_user), nb_people: 2, vibe_id: vibe_id)

    delete "/api/vibes/#{vibe_id}", as: :json

    assert_response :ok
    assert JSON.parse(response.body)["success"]
    assert_not_nil Vibe.unscoped.find(vibe_id).deleted_at
  end

  # ══════════════════════════════════════════
  # RESTORE — PATCH /api/vibes/:id/restore
  # ══════════════════════════════════════════

  test "restore retourne 200 et success true" do
    patch "/api/vibes/#{@archived_vibe.id}/restore", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Hash, json["data"]
  end

  test "restore met deleted_at à nil en base de données" do
    patch "/api/vibes/#{@archived_vibe.id}/restore", as: :json

    assert_nil Vibe.unscoped.find(@archived_vibe.id).deleted_at
  end

  test "restore retourne deleted_at nil dans la réponse" do
    patch "/api/vibes/#{@archived_vibe.id}/restore", as: :json

    assert_nil JSON.parse(response.body)["data"]["deleted_at"]
  end
end
