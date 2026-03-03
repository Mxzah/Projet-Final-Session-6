require "test_helper"

class CategoriesSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @entrees = categories(:entrees)
    @plats = categories(:plats)
    @desserts = categories(:desserts)

    sign_in users(:admin_user)
  end

  # ── Index ──

  test "index retourne toutes les catégories triées par position" do
    # Code http
    get "/api/categories", as: :json
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert json["success"]
    assert_equal 3, json["data"].length
    assert_equal @entrees.id, json["data"][0]["id"]
    assert_equal @plats.id, json["data"][1]["id"]
    assert_equal @desserts.id, json["data"][2]["id"]

    json["data"].each do |cat|
      assert_not_nil cat["id"]
      assert_not_nil cat["name"]
      assert_not_nil cat["position"]
      assert_not_nil cat["created_at"]
    end
  end

  test "index fonctionne sans authentification" do
    sign_out :user

    # Code http
    get "/api/categories", as: :json
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert json["success"]
    assert_equal 3, json["data"].length
  end

  # ── Create ──

  test "create avec nom et position valides" do
    # Code http
    assert_difference "Category.count", 1 do
      post "/api/categories", params: {
        category: { name: "Boissons", position: 3 }
      }, as: :json
    end
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert json["success"]
    assert_equal 4, json["data"].length

    # Validation de la cohérence de la base de données
    created = Category.find_by(name: "Boissons")
    assert_not_nil created
    assert_equal 3, created.position
  end

  test "create avec position existante décale les autres" do
    # Code http
    assert_difference "Category.count", 1 do
      post "/api/categories", params: {
        category: { name: "Soupes", position: 1 }
      }, as: :json
    end
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert json["success"]

    # Validation de la cohérence de la base de données
    soupes = Category.find_by(name: "Soupes")
    @plats.reload
    @desserts.reload

    assert_equal 1, soupes.position
    assert_equal 2, @plats.position
    assert_equal 3, @desserts.position
  end

  # ── Update ──

  test "update modifie le nom" do
    # Code http
    patch "/api/categories/#{@plats.id}", params: {
      category: { name: "Plats chauds" }
    }, as: :json
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert json["success"]
    assert_equal 3, json["data"].length

    # Validation de la cohérence de la base de données
    @plats.reload
    assert_equal "Plats chauds", @plats.name
  end

  test "update modifie la position avec décalage auto" do
    # Code http
    patch "/api/categories/#{@desserts.id}", params: {
      category: { position: 0 }
    }, as: :json
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert json["success"]

    # Validation de la cohérence de la base de données
    @entrees.reload
    @plats.reload
    @desserts.reload

    assert_equal 0, @desserts.position
    assert_equal 1, @entrees.position
    assert_equal 2, @plats.position
  end

  # ── Reorder ──

  test "reorder inverse l'ordre des catégories" do
    # Code http
    patch "/api/categories/reorder", params: {
      ids: [ @desserts.id, @plats.id, @entrees.id ]
    }, as: :json
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert json["success"]
    assert_equal 3, json["data"].length
    assert_equal @desserts.id, json["data"][0]["id"]
    assert_equal @plats.id, json["data"][1]["id"]
    assert_equal @entrees.id, json["data"][2]["id"]

    # Validation de la cohérence de la base de données
    @entrees.reload
    @plats.reload
    @desserts.reload

    assert_equal 2, @entrees.position
    assert_equal 1, @plats.position
    assert_equal 0, @desserts.position
  end

  test "reorder déplace une catégorie au milieu" do
    # Code http
    patch "/api/categories/reorder", params: {
      ids: [ @entrees.id, @desserts.id, @plats.id ]
    }, as: :json
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert json["success"]
    assert_equal @entrees.id, json["data"][0]["id"]
    assert_equal @desserts.id, json["data"][1]["id"]
    assert_equal @plats.id, json["data"][2]["id"]

    # Validation de la cohérence de la base de données
    @entrees.reload
    @plats.reload
    @desserts.reload

    assert_equal 0, @entrees.position
    assert_equal 1, @desserts.position
    assert_equal 2, @plats.position
  end

  # ── Destroy ──

  test "destroy supprime une catégorie sans items" do
    # Code http
    assert_difference "Category.count", -1 do
      delete "/api/categories/#{@plats.id}", as: :json
    end
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert json["success"]

    # Validation de la cohérence de la base de données
    assert_nil Category.find_by(id: @plats.id)
  end

  test "destroy supprime une autre catégorie sans items" do
    # Code http
    assert_difference "Category.count", -1 do
      delete "/api/categories/#{@desserts.id}", as: :json
    end
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert json["success"]

    # Validation de la cohérence de la base de données
    assert_nil Category.find_by(id: @desserts.id)
  end
end
