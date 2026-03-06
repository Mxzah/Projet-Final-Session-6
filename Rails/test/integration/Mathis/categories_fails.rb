# frozen_string_literal: true

require "test_helper"

class CategoriesFailsTest < ActionDispatch::IntegrationTest
  setup do
    @entrees = categories(:entrees)
    @plats = categories(:plats)
    @desserts = categories(:desserts)
    @client = users(:valid_user)

    sign_in users(:admin_user)
  end

  # ── Create fails ──

  test "create sans nom retourne success false" do
    # Code http
    assert_no_difference "Category.count" do
      post "/api/categories", params: {
        category: { name: "" }
      }, as: :json
    end
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert_not json["success"]
    assert_not_empty json["errors"]
  end

  test "create avec nom d'espaces seulement retourne success false" do
    # Code http
    assert_no_difference "Category.count" do
      post "/api/categories", params: {
        category: { name: "   " }
      }, as: :json
    end
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert_not json["success"]
    assert_not_empty json["errors"]
  end

  test "create avec nom dépassant 100 caractères retourne success false" do
    # Code http
    assert_no_difference "Category.count" do
      post "/api/categories", params: {
        category: { name: "A" * 101 }
      }, as: :json
    end
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert_not json["success"]
    assert_not_empty json["errors"]
  end

  test "create avec nom déjà existant retourne success false" do
    # Code http
    assert_no_difference "Category.count" do
      post "/api/categories", params: {
        category: { name: "Entrées" }
      }, as: :json
    end
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert_not json["success"]
    assert_not_empty json["errors"]
  end

  test "create avec un compte client retourne success false" do
    sign_out :user
    sign_in @client

    # Code http
    assert_no_difference "Category.count" do
      post "/api/categories", params: {
        category: { name: "Boissons" }
      }, as: :json
    end
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert_not json["success"]
    assert_includes json["errors"], I18n.t("controllers.admin.access_restricted")
  end

  test "create sans authentification retourne success false" do
    sign_out :user

    # Code http
    assert_no_difference "Category.count" do
      post "/api/categories", params: {
        category: { name: "Boissons" }
      }, as: :json
    end

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert_not json["success"]
  end

  # ── Update fails ──

  test "update avec nom vide retourne success false" do
    original_name = @plats.name

    # Code http
    patch "/api/categories/#{@plats.id}", params: {
      category: { name: "   " }
    }, as: :json
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert_not json["success"]
    assert_not_empty json["errors"]

    # Validation de la cohérence de la base de données
    @plats.reload
    assert_equal original_name, @plats.name
  end

  test "update avec nom dépassant 100 caractères retourne success false" do
    original_name = @plats.name

    # Code http
    patch "/api/categories/#{@plats.id}", params: {
      category: { name: "A" * 101 }
    }, as: :json
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert_not json["success"]
    assert_not_empty json["errors"]

    # Validation de la cohérence de la base de données
    @plats.reload
    assert_equal original_name, @plats.name
  end

  test "update avec nom déjà pris retourne success false" do
    original_name = @plats.name

    # Code http
    patch "/api/categories/#{@plats.id}", params: {
      category: { name: "Entrées" }
    }, as: :json
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert_not json["success"]
    assert_not_empty json["errors"]

    # Validation de la cohérence de la base de données
    @plats.reload
    assert_equal original_name, @plats.name
  end

  test "update avec un compte client retourne success false" do
    sign_out :user
    sign_in @client
    original_name = @plats.name

    # Code http
    patch "/api/categories/#{@plats.id}", params: {
      category: { name: "Nouveau nom" }
    }, as: :json
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert_not json["success"]
    assert_includes json["errors"], I18n.t("controllers.admin.access_restricted")

    # Validation de la cohérence de la base de données
    @plats.reload
    assert_equal original_name, @plats.name
  end

  test "update sans authentification retourne success false" do
    sign_out :user
    original_name = @plats.name

    # Code http
    patch "/api/categories/#{@plats.id}", params: {
      category: { name: "Nouveau nom" }
    }, as: :json

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert_not json["success"]

    # Validation de la cohérence de la base de données
    @plats.reload
    assert_equal original_name, @plats.name
  end

  # ── Reorder fails ──

  test "reorder avec un compte client retourne success false" do
    sign_out :user
    sign_in @client

    # Code http
    patch "/api/categories/reorder", params: {
      ids: [ @desserts.id, @plats.id, @entrees.id ]
    }, as: :json
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert_not json["success"]
    assert_includes json["errors"], I18n.t("controllers.admin.access_restricted")

    # Validation de la cohérence de la base de données
    @entrees.reload
    @plats.reload
    @desserts.reload
    assert_equal 0, @entrees.position
    assert_equal 1, @plats.position
    assert_equal 2, @desserts.position
  end

  test "reorder sans authentification retourne success false" do
    sign_out :user

    # Code http
    patch "/api/categories/reorder", params: {
      ids: [ @desserts.id, @plats.id, @entrees.id ]
    }, as: :json

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert_not json["success"]

    # Validation de la cohérence de la base de données
    @entrees.reload
    @plats.reload
    @desserts.reload
    assert_equal 0, @entrees.position
    assert_equal 1, @plats.position
    assert_equal 2, @desserts.position
  end

  # ── Destroy fails ──

  test "destroy d'une catégorie avec items retourne success false" do
    # Code http
    assert_no_difference "Category.count" do
      delete "/api/categories/#{@entrees.id}", as: :json
    end
    assert_response :ok

    # Format json valide
    json = JSON.parse(response.body)

    # Contenu du format json
    assert_not json["success"]
    assert_not_empty json["errors"]

    # Validation de la cohérence de la base de données
    assert_not_nil Category.find_by(id: @entrees.id)
  end
end
