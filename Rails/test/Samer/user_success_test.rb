require "test_helper"

class UserSuccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @client = users(:valid_user)
    @waiter = users(:waiter_user)
    @cook = users(:cook_user)
    @blocked = users(:blocked_user)

    sign_in @admin
  end

  # ══════════════════════════════════════════
  # LIST
  # ══════════════════════════════════════════

  test "list returns all users with success true" do
    get "/api/users"

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_instance_of Array, json["data"]

    # Database state: returned count matches DB
    assert_equal User.count, json["data"].length
  end

  # ══════════════════════════════════════════
  # READ
  # ══════════════════════════════════════════

  test "read returns user with all properties" do
    get "/api/users/#{@client.id}"

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    data = json["data"]
    assert_equal @client.id, data["id"]
    assert_equal @client.email, data["email"]
    assert_equal @client.first_name, data["first_name"]
    assert_equal @client.last_name, data["last_name"]
    assert_equal "Client", data["type"]
    assert_equal "active", data["status"]
    assert_not_nil data["created_at"]
    assert data.key?("block_note")
  end

  # ══════════════════════════════════════════
  # CREATE
  # ══════════════════════════════════════════

  test "create an Administrator with valid fields returns 200" do
    assert_difference "User.count", 1 do
      post "/api/users", params: {
        user: { first_name: "Julie", last_name: "Martin", email: "julie@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Administrator" }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal "Administrator", json["data"]["type"]

    # Database state
    created = User.find(json["data"]["id"])
    assert_equal "julie@restoqr.ca", created.email
    assert_equal "Administrator", created.type
  end

  test "create a Waiter with valid fields returns 200" do
    assert_difference "User.count", 1 do
      post "/api/users", params: {
        user: { first_name: "Paul", last_name: "Simard", email: "paul@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Waiter" }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal "Waiter", json["data"]["type"]
  end

  test "create a Cook with valid fields returns 200" do
    assert_difference "User.count", 1 do
      post "/api/users", params: {
        user: { first_name: "Anne", last_name: "Bouchard", email: "anne@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Cook" }
      }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal "Cook", json["data"]["type"]
  end

  test "create includes block_note field" do
    post "/api/users", params: {
      user: { first_name: "Luc", last_name: "Bergeron", email: "luc@restoqr.ca", password: "password123", password_confirmation: "password123", type: "Waiter", block_note: "Test note" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal "Test note", json["data"]["block_note"]

    # Database state
    created = User.find(json["data"]["id"])
    assert_equal "Test note", created.block_note
  end

  # ══════════════════════════════════════════
  # UPDATE
  # ══════════════════════════════════════════

  test "update modifies first_name and last_name" do
    patch "/api/users/#{@client.id}", params: {
      user: { first_name: "Jean-Pierre", last_name: "Tremblay-Roy" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal "Jean-Pierre", json["data"]["first_name"]
    assert_equal "Tremblay-Roy", json["data"]["last_name"]

    # Database state
    @client.reload
    assert_equal "Jean-Pierre", @client.first_name
    assert_equal "Tremblay-Roy", @client.last_name
  end

  test "update modifies email" do
    patch "/api/users/#{@client.id}", params: {
      user: { email: "nouveau@restoqr.ca" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal "nouveau@restoqr.ca", json["data"]["email"]

    # Database state
    @client.reload
    assert_equal "nouveau@restoqr.ca", @client.email
  end

  test "update modifies type" do
    patch "/api/users/#{@client.id}", params: {
      user: { type: "Waiter" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal "Waiter", json["data"]["type"]

    # Database state: use User.find to avoid STI class mismatch
    updated = User.find(@client.id)
    assert_equal "Waiter", updated.type
  end

  test "update modifies status" do
    patch "/api/users/#{@client.id}", params: {
      user: { status: "blocked" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal "blocked", json["data"]["status"]

    # Database state
    @client.reload
    assert_equal "blocked", @client.status
  end

  test "update without password does not change password" do
    patch "/api/users/#{@client.id}", params: {
      user: { first_name: "Nouveau" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal "Nouveau", json["data"]["first_name"]

    # Database state: can still log in with original password
    sign_out @admin
    post "/users/sign_in", params: {
      user: { email: @client.email, password: "password123" }
    }, as: :json
    login_json = JSON.parse(response.body)
    assert login_json["success"]
  end

  test "update with blank password does not change password" do
    patch "/api/users/#{@client.id}", params: {
      user: { first_name: "Autre", password: "", password_confirmation: "" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal "Autre", json["data"]["first_name"]
  end

  test "update block_note" do
    patch "/api/users/#{@client.id}", params: {
      user: { block_note: "Blocked for spamming" }
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert_equal "Blocked for spamming", json["data"]["block_note"]

    # Database state
    @client.reload
    assert_equal "Blocked for spamming", @client.block_note
  end

  # ══════════════════════════════════════════
  # DELETE (soft delete)
  # ══════════════════════════════════════════

  test "delete soft-deletes the user" do
    delete "/api/users/#{@client.id}", as: :json

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]

    # Database state: deleted_at is set
    user = User.unscoped.find(@client.id)
    assert_not_nil user.deleted_at
  end

  test "soft-deleted user no longer appears in GET /api/users" do
    delete "/api/users/#{@client.id}", as: :json
    assert_response :ok

    # Re-authenticate (session lost after DELETE in integration tests)
    sign_in @admin

    get "/api/users"
    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    ids = json["data"].map { |u| u["id"] }

    # Deleted user is excluded from list
    assert_not_includes ids, @client.id
  end

  # ══════════════════════════════════════════
  # SEARCH
  # ══════════════════════════════════════════

  test "search by first_name returns matching users" do
    get "/api/users", params: { search: "Jean" }

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert json["data"].length >= 1
    json["data"].each do |user|
      assert(
        user["first_name"].downcase.include?("jean") ||
        user["last_name"].downcase.include?("jean") ||
        user["email"].downcase.include?("jean"),
        "User does not match search 'Jean'"
      )
    end
  end

  test "search by email returns matching users" do
    get "/api/users", params: { search: "test@restoqr" }

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert json["data"].length >= 1
  end

  # ══════════════════════════════════════════
  # SORT
  # ══════════════════════════════════════════

  test "sort asc returns users sorted by last_name ascending" do
    get "/api/users", params: { sort: "asc", sort_by: "last_name" }

    assert_response :ok
    json = JSON.parse(response.body)
    names = json["data"].map { |u| u["last_name"] }

    # Verify alphabetical order
    assert_equal names, names.sort
  end

  test "sort desc returns users sorted by last_name descending" do
    get "/api/users", params: { sort: "desc", sort_by: "last_name" }

    assert_response :ok
    json = JSON.parse(response.body)
    names = json["data"].map { |u| u["last_name"] }

    # Verify reverse alphabetical order
    assert_equal names, names.sort.reverse
  end

  # ══════════════════════════════════════════
  # FILTER
  # ══════════════════════════════════════════

  test "filter by status active returns only active users" do
    get "/api/users", params: { status: "active" }

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    json["data"].each do |user|
      assert_equal "active", user["status"]
    end
  end

  test "filter by type Administrator returns only admins" do
    get "/api/users", params: { type: "Administrator" }

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    json["data"].each do |user|
      assert_equal "Administrator", user["type"]
    end
  end

  test "filter by status blocked returns only blocked users" do
    get "/api/users", params: { status: "blocked" }

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    assert json["data"].length >= 1
    json["data"].each do |user|
      assert_equal "blocked", user["status"]
    end
  end

  test "combined filter status active and type Client returns correct results" do
    get "/api/users", params: { status: "active", type: "Client" }

    assert_response :ok
    json = JSON.parse(response.body)

    # JSON response
    assert json["success"]
    json["data"].each do |user|
      assert_equal "active", user["status"]
      assert_equal "Client", user["type"]
    end
  end
end
