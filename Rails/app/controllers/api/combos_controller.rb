module Api
  class CombosController < AdminController
    skip_before_action :authenticate_user!, only: [ :index ]
    skip_before_action :require_admin!, only: [ :index ]

    # GET /api/combos?search=…&sort=asc|desc&price_min=…&price_max=…&include_deleted=true
    def index
      combos = if params[:include_deleted] == "true" && current_user&.type == "Administrator"
                 Combo.unscoped.includes(:availabilities)
      else
                 Combo.includes(:availabilities)
      end

      # Filtrer par disponibilité active (sauf admin avec include_deleted ou admin=true)
      unless current_user&.type == "Administrator" && (params[:admin] == "true" || params[:include_deleted] == "true")
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
      when "asc"
        combos = combos.order(price: :asc)
      when "desc"
        combos = combos.order(price: :desc)
      else
        combos = combos.order(created_at: :desc)
      end

      render_success(data: combos.map(&:as_json), errors: [])
    end

    def create
      combo = Combo.new(combo_params)

      if combo.save
        render_success(data: combo.as_json, errors: [])
      else
        render_error(combo.errors.full_messages)
      end
    end

    private

    def combo_params
      params.require(:combo).permit(:name, :description, :price, :image)
    end
  end
end
