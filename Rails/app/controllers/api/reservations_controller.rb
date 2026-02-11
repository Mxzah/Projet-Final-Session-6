module Api
  class ReservationsController < ApplicationController
    before_action :authenticate_user!

    # GET /api/reservations
    def index
      render json: {
        success: true,
        data: {
          message: 'Liste des réservations',
          user: {
            email: current_user.email,
            first_name: current_user.first_name,
            last_name: current_user.last_name
          }
        },
        errors: []
      }, status: :ok
    end

    # POST /api/reservations
    def create
      # Logique de création de réservation à implémenter
      render json: {
        success: true,
        data: { message: 'Réservation créée' },
        errors: []
      }, status: :ok
    end
  end
end
