require "test_helper"

class OrderSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @user  = users(:valid_user)
    @table = tables(:table_one)

    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    OrderLine.joins(:order).where(orders: { client_id: @user.id }).delete_all
    Order.where(client_id: @user.id).delete_all
  end

  # ══════════════════════════════════════════
  # INDEX — GET /api/orders
  # ══════════════════════════════════════════

  test "index retourne 200 et success true" do
    get "/api/orders", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
    assert_equal [],          json["errors"]
  end

  test "index retourne tableau vide si aucune commande" do
    get "/api/orders", as: :json

    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal [], json["data"]
  end

  test "index retourne les commandes du client après création" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json

    get "/api/orders", as: :json

    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1
    assert_equal @user.id, json["data"].first["client_id"]
  end

  test "index retourne les champs attendus dans chaque commande" do
    post "/api/orders", params: { order: { nb_people: 3, table_id: @table.id, note: "Test index" } }, as: :json

    get "/api/orders", as: :json

    order = JSON.parse(response.body)["data"].first
    assert order.key?("id")
    assert order.key?("nb_people")
    assert order.key?("note")
    assert order.key?("table_id")
    assert order.key?("table_number")
    assert order.key?("client_id")
    assert order.key?("order_lines")
    assert order.key?("created_at")
    assert order.key?("total")
    assert order.key?("vibe_image")
  end

  test "index filtre les commandes fermées avec le paramètre closed=true" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    post "/api/orders/close_open", as: :json

    get "/api/orders?closed=true", as: :json

    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1
    assert_not_nil json["data"].first["ended_at"]
  end

  # ══════════════════════════════════════════
  # SHOW — GET /api/orders/:id
  # ══════════════════════════════════════════

  test "show retourne 200 et success true" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    order_id = JSON.parse(response.body)["data"]["id"]

    get "/api/orders/#{order_id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Hash, json["data"]
  end

  test "show retourne les données correctes de la commande" do
    post "/api/orders", params: { order: { nb_people: 4, table_id: @table.id, note: "Sans gluten" } }, as: :json
    order_id = JSON.parse(response.body)["data"]["id"]

    get "/api/orders/#{order_id}", as: :json

    order = JSON.parse(response.body)["data"]
    assert_equal order_id,       order["id"]
    assert_equal 4,              order["nb_people"]
    assert_equal "Sans gluten",  order["note"]
    assert_equal @table.id,      order["table_id"]
    assert_equal @table.number,  order["table_number"]
    assert_equal @user.id,       order["client_id"]
  end

  # ══════════════════════════════════════════
  # CREATE — POST /api/orders
  # ══════════════════════════════════════════

  test "create retourne 200 et success true" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Hash, json["data"]
    assert_equal [],         json["errors"]
  end

  test "create retourne les champs corrects" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json

    order = JSON.parse(response.body)["data"]
    assert_equal 2,         order["nb_people"]
    assert_equal @table.id, order["table_id"]
    assert_equal @user.id,  order["client_id"]
    assert_nil              order["ended_at"]
  end

  test "create avec note retourne la note dans la réponse" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id, note: "Allergie noix" } }, as: :json

    assert_equal "Allergie noix", JSON.parse(response.body)["data"]["note"]
  end

  test "create sauvegarde la commande en base de données" do
    assert_difference "Order.count", 1 do
      post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    end
  end

  # ══════════════════════════════════════════
  # UPDATE — PUT /api/orders/:id
  # ══════════════════════════════════════════

  test "update retourne 200 et success true avec note mise à jour" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    order_id = JSON.parse(response.body)["data"]["id"]

    put "/api/orders/#{order_id}", params: { order: { note: "Extra pain" } }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Extra pain", json["data"]["note"]
  end

  test "update persiste la note en base de données" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    order_id = JSON.parse(response.body)["data"]["id"]

    put "/api/orders/#{order_id}", params: { order: { note: "Menu végétarien" } }, as: :json

    assert_equal "Menu végétarien", Order.find(order_id).note
  end

  # ══════════════════════════════════════════
  # PAY — POST /api/orders/:id/pay
  # ══════════════════════════════════════════

  test "pay retourne 200 et success true pour commande sans lignes" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    order_id = JSON.parse(response.body)["data"]["id"]

    post "/api/orders/#{order_id}/pay", params: { tip: 5.0 }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Hash, json["data"]
  end

  test "pay ferme la commande (ended_at renseigné)" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    order_id = JSON.parse(response.body)["data"]["id"]

    post "/api/orders/#{order_id}/pay", params: { tip: 0 }, as: :json

    assert_not_nil Order.unscoped.find(order_id).ended_at
  end

  test "pay sauvegarde le tip correct" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    order_id = JSON.parse(response.body)["data"]["id"]

    post "/api/orders/#{order_id}/pay", params: { tip: 12.5 }, as: :json

    assert_equal 12.5, Order.unscoped.find(order_id).tip.to_f
  end

  # ══════════════════════════════════════════
  # CLOSE_OPEN — POST /api/orders/close_open
  # ══════════════════════════════════════════

  test "close_open ferme toutes les commandes ouvertes du client" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    order_id = JSON.parse(response.body)["data"]["id"]

    post "/api/orders/close_open", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not_nil Order.unscoped.find(order_id).ended_at
  end

  test "close_open retourne success true même si aucune commande ouverte" do
    post "/api/orders/close_open", as: :json

    assert_response :ok
    assert JSON.parse(response.body)["success"]
  end

  # ══════════════════════════════════════════
  # DESTROY — DELETE /api/orders/:id
  # ══════════════════════════════════════════

  test "destroy retourne 200 et success true" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    order_id = JSON.parse(response.body)["data"]["id"]

    delete "/api/orders/#{order_id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal [], json["data"]
  end

  test "destroy supprime la commande de la base de données" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    order_id = JSON.parse(response.body)["data"]["id"]

    assert_difference "Order.unscoped.count", -1 do
      delete "/api/orders/#{order_id}", as: :json
    end
  end
end
