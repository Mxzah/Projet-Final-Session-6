# frozen_string_literal: true

require "test_helper"

class ItemsFailsTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:entrees)
    @item_one = items(:item_one)       # Tartare, 24.99$
    @item_two = items(:item_two)       # Bruschetta, 14.50$
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

  # ── Create fails ──

  test "create sans nom retourne success false" do
    assert_no_difference "Item.count" do
      post "/api/items", params: {
        item: { price: 10.00, category_id: @category.id,
                image: fixture_file_upload("test.jpg", "image/jpeg") }
      }
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]
  end

  test "create avec nom d'espaces seulement retourne success false" do
    assert_no_difference "Item.count" do
      post "/api/items", params: {
        item: { name: "   ", price: 10.00, category_id: @category.id,
                image: fixture_file_upload("test.jpg", "image/jpeg") }
      }
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]
  end

  test "create avec nom dépassant 100 caractères retourne success false" do
    assert_no_difference "Item.count" do
      post "/api/items", params: {
        item: { name: "A" * 101, price: 10.00, category_id: @category.id,
                image: fixture_file_upload("test.jpg", "image/jpeg") }
      }
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]
  end

  test "create sans prix retourne success false" do
    assert_no_difference "Item.count" do
      post "/api/items", params: {
        item: { name: "Item", category_id: @category.id,
                image: fixture_file_upload("test.jpg", "image/jpeg") }
      }
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]
  end

  test "create avec prix négatif retourne success false" do
    assert_no_difference "Item.count" do
      post "/api/items", params: {
        item: { name: "Item", price: -1, category_id: @category.id,
                image: fixture_file_upload("test.jpg", "image/jpeg") }
      }
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]
  end

  test "create avec prix supérieur à 9999.99 retourne success false" do
    assert_no_difference "Item.count" do
      post "/api/items", params: {
        item: { name: "Item", price: 10_000.00, category_id: @category.id,
                image: fixture_file_upload("test.jpg", "image/jpeg") }
      }
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]
  end

  test "create avec description dépassant 255 caractères retourne success false" do
    assert_no_difference "Item.count" do
      post "/api/items", params: {
        item: { name: "Item", description: "A" * 256, price: 10.00,
                category_id: @category.id,
                image: fixture_file_upload("test.jpg", "image/jpeg") }
      }
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]
  end

  test "create sans image retourne success false" do
    assert_no_difference "Item.count" do
      post "/api/items", params: {
        item: { name: "Item", price: 10.00, category_id: @category.id }
      }, as: :json
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]
  end

  test "create avec image GIF retourne success false" do
    assert_no_difference "Item.count" do
      post "/api/items", params: {
        item: { name: "Item", price: 10.00, category_id: @category.id,
                image: fixture_file_upload("test.gif", "image/gif") }
      }
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]
  end

  test "create avec catégorie inexistante retourne success false" do
    assert_no_difference "Item.count" do
      post "/api/items", params: {
        item: { name: "Item", price: 10.00, category_id: 999_999,
                image: fixture_file_upload("test.jpg", "image/jpeg") }
      }
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
  end

  test "create avec un compte client retourne success false" do
    sign_out :user
    sign_in @client

    assert_no_difference "Item.count" do
      post "/api/items", params: {
        item: { name: "Item Client", price: 10.00, category_id: @category.id,
                image: fixture_file_upload("test.jpg", "image/jpeg") }
      }
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_includes json["errors"], I18n.t("controllers.admin.access_restricted")
  end

  test "create sans authentification retourne success false" do
    sign_out :user

    assert_no_difference "Item.count" do
      post "/api/items", params: {
        item: { name: "Item Anon", price: 10.00, category_id: @category.id,
                image: fixture_file_upload("test.jpg", "image/jpeg") }
      }
    end

    json = JSON.parse(response.body)

    assert_not json["success"]
  end

  # ── Update fails ──

  test "update avec nom vide retourne success false" do
    original_name = @item_one.name

    patch "/api/items/#{@item_one.id}", params: {
      item: { name: "" }
    }, as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]

    # Validation de la cohérence de la base de données
    @item_one.reload
    assert_equal original_name, @item_one.name
  end

  test "update avec nom d'espaces seulement retourne success false" do
    original_name = @item_one.name

    patch "/api/items/#{@item_one.id}", params: {
      item: { name: "   " }
    }, as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]

    # Validation de la cohérence de la base de données
    @item_one.reload
    assert_equal original_name, @item_one.name
  end

  test "update avec nom dépassant 100 caractères retourne success false" do
    original_name = @item_one.name

    patch "/api/items/#{@item_one.id}", params: {
      item: { name: "A" * 101 }
    }, as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]

    # Validation de la cohérence de la base de données
    @item_one.reload
    assert_equal original_name, @item_one.name
  end

  test "update avec prix négatif retourne success false" do
    original_price = @item_one.price

    patch "/api/items/#{@item_one.id}", params: {
      item: { price: -1 }
    }, as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]

    # Validation de la cohérence de la base de données
    @item_one.reload
    assert_equal original_price, @item_one.price
  end

  test "update avec prix supérieur à 9999.99 retourne success false" do
    original_price = @item_one.price

    patch "/api/items/#{@item_one.id}", params: {
      item: { price: 10_000.00 }
    }, as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]

    # Validation de la cohérence de la base de données
    @item_one.reload
    assert_equal original_price, @item_one.price
  end

  test "update avec description dépassant 255 caractères retourne success false" do
    original_desc = @item_one.description

    patch "/api/items/#{@item_one.id}", params: {
      item: { description: "A" * 256 }
    }, as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]

    # Validation de la cohérence de la base de données
    @item_one.reload
    assert_equal original_desc, @item_one.description
  end

  test "update avec image GIF retourne success false" do
    patch "/api/items/#{@item_one.id}", params: {
      item: { image: fixture_file_upload("test.gif", "image/gif") }
    }
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_not_empty json["errors"]
  end

  test "update avec catégorie inexistante retourne success false" do
    original_category_id = @item_one.category_id

    patch "/api/items/#{@item_one.id}", params: {
      item: { category_id: 999_999 }
    }, as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]

    # Validation de la cohérence de la base de données
    @item_one.reload
    assert_equal original_category_id, @item_one.category_id
  end

  test "update d'un item archivé retourne success false" do
    @item_one.soft_delete!
    original_name = Item.unscoped.find(@item_one.id).name

    patch "/api/items/#{@item_one.id}", params: {
      item: { name: "Modification interdite" }
    }, as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_includes json["errors"], I18n.t("controllers.items.cannot_update_archived")

    # Validation de la cohérence de la base de données
    assert_equal original_name, Item.unscoped.find(@item_one.id).name
  end

  test "update avec un compte client retourne success false" do
    sign_out :user
    sign_in @client
    original_name = @item_one.name

    patch "/api/items/#{@item_one.id}", params: {
      item: { name: "Modifié par client" }
    }, as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_includes json["errors"], I18n.t("controllers.admin.access_restricted")

    # Validation de la cohérence de la base de données
    @item_one.reload
    assert_equal original_name, @item_one.name
  end

  test "update sans authentification retourne success false" do
    sign_out :user
    original_name = @item_one.name

    patch "/api/items/#{@item_one.id}", params: {
      item: { name: "Modifié anonymement" }
    }, as: :json

    json = JSON.parse(response.body)

    assert_not json["success"]

    # Validation de la cohérence de la base de données
    @item_one.reload
    assert_equal original_name, @item_one.name
  end

  # ── Destroy fails ──

  test "destroy avec un compte client retourne success false" do
    sign_out :user
    sign_in @client

    delete "/api/items/#{@item_one.id}", as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_includes json["errors"], I18n.t("controllers.admin.access_restricted")

    # Validation de la cohérence de la base de données
    assert_nil Item.find(@item_one.id).deleted_at
  end

  test "destroy sans authentification retourne success false" do
    sign_out :user

    delete "/api/items/#{@item_one.id}", as: :json

    json = JSON.parse(response.body)

    assert_not json["success"]

    # Validation de la cohérence de la base de données
    assert_nil Item.find(@item_one.id).deleted_at
  end

  # ── Hard destroy fails ──

  test "hard_destroy d'un item avec commandes retourne success false" do
    # item_one a une order_line dans les fixtures
    assert_no_difference "Item.unscoped.count" do
      delete "/api/items/#{@item_one.id}/hard", as: :json
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_includes json["errors"], I18n.t("controllers.items.cannot_hard_delete")

    # Validation de la cohérence de la base de données
    assert_not_nil Item.find_by(id: @item_one.id)
  end

  test "hard_destroy avec un compte client retourne success false" do
    sign_out :user
    sign_in @client

    assert_no_difference "Item.unscoped.count" do
      delete "/api/items/#{@item_two.id}/hard", as: :json
    end
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
    assert_includes json["errors"], I18n.t("controllers.admin.access_restricted")

    # Validation de la cohérence de la base de données
    assert_not_nil Item.find_by(id: @item_two.id)
  end

  # ── Show fails ──

  test "show avec ID inexistant retourne success false" do
    get "/api/items/999999", as: :json
    assert_response :ok

    json = JSON.parse(response.body)

    assert_not json["success"]
  end

  # ── Index admin fails ──

  test "client avec admin=true ne voit pas les items archivés" do
    @item_one.soft_delete!
    sign_out :user
    sign_in @client

    get "/api/items", params: { admin: true }
    assert_response :ok

    json = JSON.parse(response.body)

    ids = json["data"].map { |i| i["id"] }
    assert_not_includes ids, @item_one.id
  end

  test "sans admin=true l'item dans catégorie sans availability est exclu" do
    category_desserts = categories(:desserts)
    item = Item.new(name: "Tiramisu", description: "Dessert", price: 11.50, category: category_desserts)
    item.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")),
                      filename: "test.jpg", content_type: "image/jpeg")
    item.save!

    Availability.create!(
      available_type: "Item", available_id: item.id,
      start_at: Time.current.beginning_of_minute, end_at: nil
    )

    # La catégorie desserts n'a aucune availability active
    now = Time.current
    assert_equal 0, Availability.where(available_type: "Category", available_id: category_desserts.id)
                                .where("start_at <= ? AND (end_at IS NULL OR end_at > ?)", now, now).count

    sign_out :user

    get "/api/items"
    assert_response :ok

    json = JSON.parse(response.body)

    ids = json["data"].map { |i| i["id"] }
    assert_not_includes ids, item.id
  end

end
