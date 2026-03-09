# frozen_string_literal: true

require "test_helper"

class ItemsStatsSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:entrees)
    @category2 = categories(:plats)
    @item_one = items(:item_one)       # Tartare, 24.99$, entrees
    @item_two = items(:item_two)       # Bruschetta, 14.50$, entrees
    @item_three = items(:item_three)   # Salade César, 16.99$, entrees
    @client = users(:valid_user)

    # Attacher une image aux fixtures
    [@item_one, @item_two, @item_three].each do |item|
      item.image.attach(
        io: File.open(Rails.root.join("test/fixtures/files/test.jpg")),
        filename: "test.jpg", content_type: "image/jpeg"
      )
    end

    sign_in users(:admin_user)
  end

  # ── Accès et structure de base ──

  test "stats retourne success true avec colonnes et lignes" do
    get "/api/items/stats", as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert json["success"]
    assert_not_nil json["data"]["columns"]
    assert_not_nil json["data"]["rows"]
    assert json["data"]["columns"].length >= 1
    assert_instance_of Array, json["data"]["rows"]

    # Validation de la cohérence de la base de données
    assert_equal Item.unscoped.count, json["data"]["rows"].length
  end

  test "stats retourne toutes les colonnes attendues" do
    get "/api/items/stats", as: :json
    assert_response :ok

    json = JSON.parse(response.body)
    columns = json["data"]["columns"].map { |c| c["key"] }

    expected_keys = %w[item_name category_name availability total_orders
                       total_order_lines combos_count ordered_individually
                       ordered_via_combo avg_quantity]

    expected_keys.each do |key|
      assert_includes columns, key, "La colonne #{key} est manquante"
    end
  end

  test "stats retourne les labels de colonnes" do
    get "/api/items/stats", as: :json
    assert_response :ok

    json = JSON.parse(response.body)
    labels = json["data"]["columns"].map { |c| c["label"] }

    assert_includes labels, "Item"
    assert_includes labels, "Catégorie"
    assert_includes labels, "Disponibilité"
    assert_includes labels, "Nb commandes"
  end

  test "stats retourne tous les items actifs" do
    get "/api/items/stats", as: :json
    assert_response :ok

    json = JSON.parse(response.body)
    names = json["data"]["rows"].map { |r| r["item_name"] }

    assert_includes names, @item_one.name
    assert_includes names, @item_two.name
    assert_includes names, @item_three.name

    # Validation de la cohérence de la base de données
    db_names = Item.pluck(:name)
    db_names.each do |name|
      assert_includes names, name, "L'item #{name} en BD n'apparaît pas dans les stats"
    end
  end

  # ── Données de commandes ──

  test "stats item avec commandes affiche les bonnes statistiques" do
    get "/api/items/stats", as: :json
    assert_response :ok

    json = JSON.parse(response.body)
    row = json["data"]["rows"].find { |r| r["item_name"] == @item_one.name }

    assert_not_nil row
    assert_equal 1, row["total_orders"]
    assert_equal 1, row["total_order_lines"]
    assert_equal 2, row["ordered_individually"]
    assert_equal 2, row["avg_quantity"]

    # Validation de la cohérence de la base de données
    db_order_lines = OrderLine.where(orderable_type: "Item", orderable_id: @item_one.id)
    assert_equal db_order_lines.count, row["total_order_lines"]
    assert_equal db_order_lines.distinct.count(:order_id), row["total_orders"]
    assert_equal db_order_lines.sum(:quantity), row["ordered_individually"]
  end

  test "stats item sans commandes affiche 0 pour les colonnes numériques" do
    get "/api/items/stats", as: :json
    assert_response :ok

    json = JSON.parse(response.body)
    row = json["data"]["rows"].find { |r| r["item_name"] == @item_three.name }

    assert_not_nil row
    assert_equal 0, row["total_orders"]
    assert_equal 0, row["total_order_lines"]
    assert_equal 0, row["ordered_individually"]
    assert_equal 0, row["avg_quantity"]

    # Validation de la cohérence de la base de données
    assert_equal 0, OrderLine.where(orderable_type: "Item", orderable_id: @item_three.id).count
  end

  test "stats affiche le nom de la catégorie" do
    get "/api/items/stats", as: :json
    assert_response :ok

    json = JSON.parse(response.body)
    row = json["data"]["rows"].find { |r| r["item_name"] == @item_one.name }

    assert_equal @category.name, row["category_name"]

    # Validation de la cohérence de la base de données
    @item_one.reload
    assert_equal @item_one.category.name, row["category_name"]
  end

  # ── Tri ──

  test "stats trie les items par nombre de commandes décroissant" do
    get "/api/items/stats", as: :json
    assert_response :ok

    json = JSON.parse(response.body)
    rows = json["data"]["rows"].reject { |r| r["is_deleted"] == 1 }
    orders = rows.map { |r| r["total_orders"] }

    assert_equal orders, orders.sort.reverse
  end

  # ── Disponibilité sans filtres de dates ──

  test "stats sans filtres de date affiche N/A pour la disponibilité" do
    get "/api/items/stats", as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    json["data"]["rows"].each do |row|
      assert_equal "N/A", row["availability"],
                   "L'item #{row['item_name']} devrait afficher N/A sans filtre de date"
    end
  end

  # ── Filtres de dates ──

  test "stats avec filtres de date retourne la colonne availability" do
    get "/api/items/stats", params: {
      start_date: 1.month.ago.strftime("%Y-%m-%d"),
      end_date: Date.today.strftime("%Y-%m-%d")
    }
    assert_response :ok

    json = JSON.parse(response.body)

    assert json["success"]
    columns = json["data"]["columns"].map { |c| c["key"] }
    assert_includes columns, "availability"
  end

  test "stats avec filtres de date affiche Oui Non ou Partielle" do
    get "/api/items/stats", params: {
      start_date: 1.month.ago.strftime("%Y-%m-%d"),
      end_date: Date.today.strftime("%Y-%m-%d")
    }
    assert_response :ok

    json = JSON.parse(response.body)
    valid_values = %w[Oui Non Partielle]

    json["data"]["rows"].each do |row|
      assert_includes valid_values, row["availability"],
                      "L'item #{row['item_name']} a une disponibilité inattendue: #{row['availability']}"
    end
  end

  test "stats availability Oui pour un item avec disponibilité couvrant toute la période" do
    # item_one a item_one_active: start_at 1.hour.ago, end_at 1.day.from_now
    get "/api/items/stats", params: {
      start_date: Date.today.strftime("%Y-%m-%d"),
      end_date: Date.today.strftime("%Y-%m-%d")
    }
    assert_response :ok

    json = JSON.parse(response.body)
    row = json["data"]["rows"].find { |r| r["item_name"] == @item_one.name }

    assert_equal "Oui", row["availability"]

    # Validation de la cohérence de la base de données
    now = Date.today
    covering = Availability.where(available_type: "Item", available_id: @item_one.id)
                           .where("DATE(start_at) <= ?", now)
                           .where("end_at IS NULL OR DATE(end_at) >= ?", now)
    assert covering.exists?, "L'item devrait avoir une disponibilité couvrant la période en BD"
  end

  test "stats availability Non pour un item sans aucune disponibilité" do
    item = Item.new(name: "Sans Dispo", description: "Test", price: 10.00, category: @category)
    item.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")),
                      filename: "test.jpg", content_type: "image/jpeg")
    item.save!

    get "/api/items/stats", params: {
      start_date: 1.month.ago.strftime("%Y-%m-%d"),
      end_date: Date.today.strftime("%Y-%m-%d")
    }
    assert_response :ok

    json = JSON.parse(response.body)
    row = json["data"]["rows"].find { |r| r["item_name"] == "Sans Dispo" }

    assert_not_nil row
    assert_equal "Non", row["availability"]

    # Validation de la cohérence de la base de données
    assert_equal 0, Availability.where(available_type: "Item", available_id: item.id).count
  end

  test "stats availability Partielle pour un item avec disponibilité partielle" do
    item = Item.new(name: "Dispo Partielle", description: "Test", price: 10.00, category: @category)
    item.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")),
                      filename: "test.jpg", content_type: "image/jpeg")
    item.save!

    avail = Availability.new(
      available_type: "Item", available_id: item.id,
      start_at: Time.current, end_at: 1.day.from_now
    )
    avail.save(validate: false)

    start_date = 1.week.ago.strftime("%Y-%m-%d")
    end_date = 1.day.from_now.strftime("%Y-%m-%d")

    get "/api/items/stats", params: {
      start_date: start_date,
      end_date: end_date
    }
    assert_response :ok

    json = JSON.parse(response.body)
    row = json["data"]["rows"].find { |r| r["item_name"] == "Dispo Partielle" }

    assert_not_nil row
    assert_equal "Partielle", row["availability"]

    # Validation de la cohérence de la base de données
    # L'availability existe mais ne couvre pas toute la période (start_at > start_date)
    db_avail = Availability.where(available_type: "Item", available_id: item.id).first
    assert_not_nil db_avail
    assert db_avail.start_at.to_date > 1.week.ago.to_date,
           "La disponibilité ne devrait pas couvrir le début de la période"
  end

  # ── Filtres de dates et commandes ──

  test "stats avec filtre de date les items sans commandes restent visibles" do
    future_date = 1.day.from_now.strftime("%Y-%m-%d")

    get "/api/items/stats", params: {
      start_date: future_date,
      end_date: future_date
    }
    assert_response :ok

    json = JSON.parse(response.body)
    row = json["data"]["rows"].find { |r| r["item_name"] == @item_three.name }

    assert_not_nil row, "L'item sans commandes doit apparaître même avec des filtres de date"

    # Validation de la cohérence de la base de données
    assert_not_nil Item.find_by(name: @item_three.name)
  end

  test "stats avec filtre de date incluant les commandes les comptabilise" do
    get "/api/items/stats", params: {
      start_date: 1.day.ago.strftime("%Y-%m-%d"),
      end_date: Date.today.strftime("%Y-%m-%d")
    }
    assert_response :ok

    json = JSON.parse(response.body)
    row = json["data"]["rows"].find { |r| r["item_name"] == @item_one.name }

    assert_not_nil row
    assert row["total_orders"] >= 1

    # Validation de la cohérence de la base de données
    db_lines = OrderLine.where(orderable_type: "Item", orderable_id: @item_one.id)
    assert db_lines.exists?, "L'item devrait avoir des order_lines en BD"
  end

  # ── Filtre par catégories ──

  test "stats avec filtre de catégorie retourne uniquement les items de la catégorie" do
    get "/api/items/stats", params: {
      category_ids: [@category.id]
    }
    assert_response :ok

    json = JSON.parse(response.body)

    assert json["success"]
    json["data"]["rows"].each do |row|
      assert_equal @category.name, row["category_name"]
    end

    # Validation de la cohérence de la base de données
    db_items_in_category = Item.unscoped.where(category_id: @category.id)
    assert_equal db_items_in_category.count, json["data"]["rows"].length
  end

  test "stats avec filtre de catégorie exclut les items d'autres catégories" do
    item = Item.new(name: "Steak Frites", description: "Test", price: 30.00, category: @category2)
    item.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")),
                      filename: "test.jpg", content_type: "image/jpeg")
    item.save!

    get "/api/items/stats", params: {
      category_ids: [@category.id]
    }
    assert_response :ok

    json = JSON.parse(response.body)
    names = json["data"]["rows"].map { |r| r["item_name"] }

    assert_not_includes names, "Steak Frites"

    # Validation de la cohérence de la base de données
    item.reload
    assert_equal @category2.id, item.category_id
    assert_not_equal @category.id, item.category_id
  end

  test "stats avec plusieurs catégories retourne les items des deux catégories" do
    item = Item.new(name: "Steak Multiple", description: "Test", price: 30.00, category: @category2)
    item.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")),
                      filename: "test.jpg", content_type: "image/jpeg")
    item.save!

    get "/api/items/stats", params: {
      category_ids: [@category.id, @category2.id]
    }
    assert_response :ok

    json = JSON.parse(response.body)
    names = json["data"]["rows"].map { |r| r["item_name"] }

    assert_includes names, @item_one.name
    assert_includes names, "Steak Multiple"

    # Validation de la cohérence de la base de données
    db_count = Item.unscoped.where(category_id: [@category.id, @category2.id]).count
    assert_equal db_count, json["data"]["rows"].length
  end

  # ── Combinaison de filtres ──

  test "stats avec filtres de date et catégorie combinés" do
    get "/api/items/stats", params: {
      start_date: 1.day.ago.strftime("%Y-%m-%d"),
      end_date: Date.today.strftime("%Y-%m-%d"),
      category_ids: [@category.id]
    }
    assert_response :ok

    json = JSON.parse(response.body)

    assert json["success"]

    # Tous les items retournés sont de la bonne catégorie
    json["data"]["rows"].each do |row|
      assert_equal @category.name, row["category_name"]
    end

    # La disponibilité n'est plus N/A (dates fournies)
    json["data"]["rows"].each do |row|
      assert_not_equal "N/A", row["availability"]
    end

    # Validation de la cohérence de la base de données
    db_items_in_category = Item.unscoped.where(category_id: @category.id)
    assert_equal db_items_in_category.count, json["data"]["rows"].length
  end

  # ── Items soft-deleted ──

  test "stats inclut les items archivés avec is_deleted à 1" do
    @item_three.soft_delete!

    get "/api/items/stats", as: :json
    assert_response :ok

    json = JSON.parse(response.body)
    row = json["data"]["rows"].find { |r| r["item_name"] == @item_three.name }

    assert_not_nil row, "L'item archivé doit apparaître dans les stats"
    assert_equal 1, row["is_deleted"]

    # Validation de la cohérence de la base de données
    db_item = Item.unscoped.find(@item_three.id)
    assert_not_nil db_item.deleted_at
  end

  test "stats items archivés apparaissent à la fin de la liste" do
    @item_three.soft_delete!

    get "/api/items/stats", as: :json
    assert_response :ok

    json = JSON.parse(response.body)
    rows = json["data"]["rows"]

    first_deleted_index = rows.index { |r| r["is_deleted"] == 1 }
    last_active_index = rows.rindex { |r| r["is_deleted"] == 0 }

    if first_deleted_index && last_active_index
      assert first_deleted_index > last_active_index,
             "Les items archivés doivent apparaître après les items actifs"
    end

    # Validation de la cohérence de la base de données
    active_count = Item.count
    deleted_count = Item.unscoped.where.not(deleted_at: nil).count
    assert_equal active_count + deleted_count, rows.length
  end

  test "stats items actifs ont is_deleted à 0" do
    get "/api/items/stats", as: :json
    assert_response :ok

    json = JSON.parse(response.body)
    row = json["data"]["rows"].find { |r| r["item_name"] == @item_one.name }

    assert_equal 0, row["is_deleted"]

    # Validation de la cohérence de la base de données
    @item_one.reload
    assert_nil @item_one.deleted_at
  end
end
