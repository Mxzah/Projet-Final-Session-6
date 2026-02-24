module Api
  class CombosController < AdminController
    skip_before_action :require_admin!, only: [:index]

    def index
      combos = Combo.includes(:availabilities).order(created_at: :desc)

      render json: {
        success: true,
        data: combos.map { |combo| combo_json(combo) },
        errors: []
      }, status: :ok
    end

    def create
      combo = Combo.new(combo_params)

      if combo.save
        render json: {
          success: true,
          data: combo_json(combo),
          errors: []
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: combo.errors.full_messages
        }, status: :ok
      end
    end

    private

    def combo_params
      params.require(:combo).permit(:name, :description, :price)
    end

    def combo_json(combo)
      {
        id: combo.id,
        name: combo.name,
        description: combo.description,
        price: combo.price.to_f,
        created_at: combo.created_at,
        availabilities: combo.availabilities.map { |a|
          { id: a.id, start_at: a.start_at, end_at: a.end_at, description: a.description }
        }
      }
    end
  end
end
