# frozen_string_literal: true

require "test_helper"

class OrderLineSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @user  = users(:valid_user)
    @table = tables(:table_one)
    @item  = items(:item_one) # disponible via fixture item_one_active

    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    OrderLine.joins(:order).where(orders: { client_id: @user.id }).delete_all
    Order.where(client_id: @user.id).delete_all

    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    @order_id = JSON.parse(response.body)["data"]["id"]
  end

  # ══════════════════════════════════════════
  # INDEX — GET /api/orders/:order_id/order_lines
  # ══════════════════════════════════════════

  test "index retourne 200 et success true" do
    get "/api/orders/#{@order_id}/order_lines", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
    assert_equal [],          json["errors"]
  end

  test "index retourne tableau vide si aucune ligne" do
    get "/api/orders/#{@order_id}/order_lines", as: :json

    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal [], json["data"]
  end

  test "index retourne les lignes après création" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item.id } },
         as: :json

    get "/api/orders/#{@order_id}/order_lines", as: :json

    json = JSON.parse(response.body)
    assert json["success"]
    assert json["data"].length >= 1
    assert_equal @item.id, json["data"].first["orderable_id"]
  end

  test "index retourne les champs attendus dans chaque ligne" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 2, orderable_type: "Item", orderable_id: @item.id, note: "Sans sel" } },
         as: :json

    get "/api/orders/#{@order_id}/order_lines", as: :json

    line = JSON.parse(response.body)["data"].first
    assert line.key?("id")
    assert line.key?("quantity")
    assert line.key?("unit_price")
    assert line.key?("note")
    assert line.key?("status")
    assert line.key?("orderable_type")
    assert line.key?("orderable_id")
    assert line.key?("orderable_name")
    assert line.key?("created_at")
  end

  # ══════════════════════════════════════════
  # CREATE — POST /api/orders/:order_id/order_lines
  # ══════════════════════════════════════════

  test "create retourne 200 et success true" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item.id } },
         as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Hash, json["data"]
    assert_equal [],         json["errors"]
  end

  test "create assigne automatiquement le unit_price depuis l item" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item.id } },
         as: :json

    json = JSON.parse(response.body)
    assert_equal @item.price.to_f, json["data"]["unit_price"]
  end

  test "create assigne le statut waiting par défaut" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item.id } },
         as: :json

    assert_equal "waiting", JSON.parse(response.body)["data"]["status"]
  end

  test "create sauvegarde la ligne en base de données" do
    assert_difference "OrderLine.count", 1 do
      post "/api/orders/#{@order_id}/order_lines",
           params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item.id } },
           as: :json
    end
  end

  test "create retourne les données correctes de la ligne" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 3, orderable_type: "Item", orderable_id: @item.id, note: "Épicé" } },
         as: :json

    line = JSON.parse(response.body)["data"]
    assert_equal 3,         line["quantity"]
    assert_equal "Épicé",   line["note"]
    assert_equal "Item",    line["orderable_type"]
    assert_equal @item.id,  line["orderable_id"]
    assert_equal @item.name, line["orderable_name"]
  end

  # ══════════════════════════════════════════
  # UPDATE — PUT /api/orders/:order_id/order_lines/:id
  # ══════════════════════════════════════════

  test "update retourne 200 et success true" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item.id } },
         as: :json
    line_id = JSON.parse(response.body)["data"]["id"]

    put "/api/orders/#{@order_id}/order_lines/#{line_id}",
        params: { order_line: { quantity: 2, note: "Extra fromage" } },
        as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Hash, json["data"]
  end

  test "update persiste les changements en base de données" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item.id } },
         as: :json
    line_id = JSON.parse(response.body)["data"]["id"]

    put "/api/orders/#{@order_id}/order_lines/#{line_id}",
        params: { order_line: { quantity: 4, note: "Sans oignons" } },
        as: :json

    line = OrderLine.find(line_id)
    assert_equal 4, line.quantity
    assert_equal "Sans oignons", line.note
  end

  # ══════════════════════════════════════════
  # DESTROY — DELETE /api/orders/:order_id/order_lines/:id
  # ══════════════════════════════════════════

  test "destroy retourne 200 et success true" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item.id } },
         as: :json
    line_id = JSON.parse(response.body)["data"]["id"]

    delete "/api/orders/#{@order_id}/order_lines/#{line_id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal [], json["data"]
  end

  test "destroy supprime la ligne de la base de données" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item.id } },
         as: :json
    line_id = JSON.parse(response.body)["data"]["id"]

    assert_difference "OrderLine.count", -1 do
      delete "/api/orders/#{@order_id}/order_lines/#{line_id}", as: :json
    end
  end

  # ══════════════════════════════════════════
  # SEND_LINES — POST /api/orders/:order_id/order_lines/send_lines
  # ══════════════════════════════════════════

  test "send_lines retourne 200 et success true" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item.id } },
         as: :json

    post "/api/orders/#{@order_id}/order_lines/send_lines", as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["success"]
    assert_instance_of Array, json["data"]
  end

  test "send_lines change le statut des lignes waiting vers sent" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item.id } },
         as: :json
    line_id = JSON.parse(response.body)["data"]["id"]

    post "/api/orders/#{@order_id}/order_lines/send_lines", as: :json

    assert_equal "sent", OrderLine.find(line_id).status
  end

  test "send_lines retourne toutes les lignes avec statut mis à jour" do
    post "/api/orders/#{@order_id}/order_lines",
         params: { order_line: { quantity: 1, orderable_type: "Item", orderable_id: @item.id } },
         as: :json

    post "/api/orders/#{@order_id}/order_lines/send_lines", as: :json

    json = JSON.parse(response.body)
    assert(json["data"].none? { |l| l["status"] == "waiting" })
  end
end
