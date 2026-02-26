module Api
  class CombosController < AdminController
    skip_before_action :authenticate_user!, only: [:index]
    skip_before_action :require_admin!, only: [:index]

    # GET /api/combos?search=…&sort=asc|desc&price_min=…&price_max=…&include_deleted=true
    def index
      combos = if params[:include_deleted] == 'true' && current_user&.is_a?(Administrator)
                 Combo.unscoped.includes(:availabilities)
               else
                 Combo.includes(:availabilities)
               end

      # Filtrer par disponibilité active (sauf admin)
      unless current_user&.type == "Administrator" && params[:admin] == "true"
        now = Time.current
        combos = combos.joins(:availabilities)
                       .where(
                         "availabilities.start_at <= ? AND (availabilities.end_at IS NULL OR availabilities.end_at > ?)",
                         now, now
                       )
                       .distinct
      end

      # Search
      if params[:search].present?
        combos = combos.where("combos.name LIKE ?", "%#{params[:search]}%")
      end

      # Price filters
      if params[:price_min].present?
        combos = combos.where("combos.price >= ?", params[:price_min].to_f)
      end
      if params[:price_max].present?
        combos = combos.where("combos.price <= ?", params[:price_max].to_f)
      end

      # Sort
      case params[:sort]
      when 'asc'
        combos = combos.order(price: :asc)
      when 'desc'
        combos = combos.order(price: :desc)
      else
        combos = combos.order(created_at: :desc)
      end

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
      params.require(:combo).permit(:name, :description, :price, :image)
    end

    def combo_json(combo)
      {
        id: combo.id,
        name: combo.name,
        description: combo.description,
        price: combo.price.to_f,
        image_url: combo.image.attached? ? url_for(combo.image) : nil,
        created_at: combo.created_at,
        deleted_at: combo.deleted_at,
        availabilities: combo.availabilities.map { |a|
          { id: a.id, start_at: a.start_at, end_at: a.end_at, description: a.description }
        }
      }
    end
  end
end
