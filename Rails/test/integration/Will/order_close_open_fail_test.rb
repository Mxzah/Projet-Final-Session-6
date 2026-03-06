# frozen_string_literal: true

require "test_helper"

class OrderCloseOpenFailTest < ActionDispatch::IntegrationTest
  # Test 1: Non authentifié → erreur
  test "close_open retourne erreur si non authentifié" do
    post "/api/orders/close_open", as: :json

    assert_response :ok
    assert_not JSON.parse(response.body)["success"]
  end
end
