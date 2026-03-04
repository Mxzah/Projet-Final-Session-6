require "test_helper"

class OrderCreateFailTest < ActionDispatch::IntegrationTest
  setup do
    @user  = users(:valid_user)
    @table = tables(:table_one)
    post "/users/sign_in", params: { user: { email: @user.email, password: "password123" } }, as: :json
    OrderLine.joins(:order).where(orders: { client_id: @user.id }).delete_all
    Order.where(client_id: @user.id).delete_all
  end

  # Test 1: Non authentifié → erreur
  test "create retourne erreur si non authentifié" do
    delete "/users/sign_out", as: :json

    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json

    assert_response :ok
    assert_not JSON.parse(response.body)["success"]
  end

  # Test 2: nb_people manquant → validation fail
  test "create retourne erreur si nb_people absent" do
    post "/api/orders", params: { order: { table_id: @table.id } }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 3: table_id manquant → validation fail
  test "create retourne erreur si table_id absent" do
    post "/api/orders", params: { order: { nb_people: 2 } }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 4: Client a déjà une commande ouverte → validation fail
  test "create retourne erreur si le client a déjà une commande ouverte" do
    post "/api/orders", params: { order: { nb_people: 2, table_id: @table.id } }, as: :json
    assert JSON.parse(response.body)["success"]

    # Tenter d'en créer une deuxième
    post "/api/orders", params: { order: { nb_people: 3, table_id: tables(:table_two).id } }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end

  # Test 5: nb_people invalide (0) → validation fail
  test "create retourne erreur si nb_people est 0" do
    post "/api/orders", params: { order: { nb_people: 0, table_id: @table.id } }, as: :json

    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any?
  end
end
