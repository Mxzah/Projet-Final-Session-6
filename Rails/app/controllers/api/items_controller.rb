# frozen_string_literal: true

module Api
  # CRUD operations for menu items
  class ItemsController < AdminController
    skip_before_action :authenticate_user!, only: [ :index ]
    skip_before_action :require_admin!, only: %i[index show]
    before_action :set_item, only: %i[show destroy hard_destroy]
    before_action :set_item_unscoped, only: %i[update restore]
    before_action :reject_if_archived, only: [ :update ]

    # GET /api/items?search=…&sort=asc|desc&price_min=…&price_max=…
    def index
      base = current_user&.type == "Administrator" ? Item.unscoped : Item
      items = base.includes(:category, :order_lines, :combo_items, :availabilities)

      unless current_user&.type == "Administrator" && params[:admin] == "true"
        now = Time.current
        items = items.joins(:availabilities)
                     .where(
                       "availabilities.start_at <= ? AND (availabilities.end_at IS NULL OR availabilities.end_at > ?)",
                       now, now
                     )
                     .distinct

        # Exclure les items dont la catégorie n'a aucune disponibilité active
        available_category_ids = Category.joins(:availabilities)
                                         .where(
                                           "availabilities.start_at <= ? AND " \
                                           "(availabilities.end_at IS NULL OR availabilities.end_at > ?)",
                                           now, now
                                         )
                                         .distinct
                                         .pluck(:id)
        items = items.where(category_id: available_category_ids)
      end

      # Search
      items = items.where("items.name LIKE ?", "%#{params[:search]}%") if params[:search].present?

      # Filter
      items = items.where("items.price >= ?", params[:price_min].to_f) if params[:price_min].present?
      items = items.where("items.price <= ?", params[:price_max].to_f) if params[:price_max].present?

      # Sort
      items = case params[:sort]
      when "asc"
                items.order(price: :asc)
      when "desc"
                items.order(price: :desc)
      else
                items.joins(:category).order("categories.position ASC, items.name ASC")
      end

      render_success(data: items.map { |i| item_json(i) }, errors: [])
    end

    # GET /api/items/stats
    def stats
      data = []

      # Items & Orders
      data << { title: "Item le plus commandé", value: sql_value("SELECT i.name FROM items i JOIN order_lines ol ON ol.orderable_id = i.id AND ol.orderable_type = 'Item' WHERE i.deleted_at IS NULL GROUP BY i.id, i.name ORDER BY SUM(ol.quantity) DESC LIMIT 1") || "Aucun" }
      data << { title: "Item le moins commandé", value: sql_value("SELECT i.name FROM items i JOIN order_lines ol ON ol.orderable_id = i.id AND ol.orderable_type = 'Item' WHERE i.deleted_at IS NULL GROUP BY i.id, i.name ORDER BY SUM(ol.quantity) ASC LIMIT 1") || "Aucun" }
      data << { title: "Item plus haut revenu", value: sql_value("SELECT i.name FROM items i JOIN order_lines ol ON ol.orderable_id = i.id AND ol.orderable_type = 'Item' WHERE i.deleted_at IS NULL GROUP BY i.id, i.name ORDER BY SUM(ol.quantity * ol.unit_price) DESC LIMIT 1") || "Aucun" }
      data << { title: "Revenu total", value: format_money(sql_value("SELECT COALESCE(SUM(ol.quantity * ol.unit_price), 0) FROM order_lines ol WHERE ol.orderable_type = 'Item'")) }
      data << { title: "Items distincts commandés", value: sql_value("SELECT COUNT(DISTINCT ol.orderable_id) FROM order_lines ol WHERE ol.orderable_type = 'Item'") || 0 }
      data << { title: "Prix moyen commandé", value: format_money(sql_value("SELECT AVG(ol.unit_price) FROM order_lines ol WHERE ol.orderable_type = 'Item'")) }
      data << { title: "Quantité moy. par ligne", value: sql_value("SELECT ROUND(AVG(ol.quantity), 2) FROM order_lines ol WHERE ol.orderable_type = 'Item'") || 0 }
      data << { title: "Lignes en attente", value: sql_value("SELECT COUNT(*) FROM order_lines ol WHERE ol.orderable_type = 'Item' AND ol.status = 'waiting'") || 0 }
      data << { title: "Lignes en préparation", value: sql_value("SELECT COUNT(*) FROM order_lines ol WHERE ol.orderable_type = 'Item' AND ol.status = 'in_preparation'") || 0 }
      data << { title: "Lignes servies", value: sql_value("SELECT COUNT(*) FROM order_lines ol WHERE ol.orderable_type = 'Item' AND ol.status = 'served'") || 0 }

      # Items & Availabilities
      data << { title: "Items disponibles", value: sql_value("SELECT COUNT(DISTINCT i.id) FROM items i JOIN availabilities a ON a.available_id = i.id AND a.available_type = 'Item' WHERE i.deleted_at IS NULL AND a.start_at <= UTC_TIMESTAMP() AND (a.end_at IS NULL OR a.end_at > UTC_TIMESTAMP())") || 0 }
      data << { title: "Items indisponibles", value: sql_value("SELECT COUNT(*) FROM items i WHERE i.deleted_at IS NULL AND NOT EXISTS (SELECT 1 FROM availabilities a WHERE a.available_id = i.id AND a.available_type = 'Item' AND a.start_at <= UTC_TIMESTAMP() AND (a.end_at IS NULL OR a.end_at > UTC_TIMESTAMP()))") || 0 }
      data << { title: "Items sans disponibilité", value: sql_value("SELECT COUNT(*) FROM items i WHERE i.deleted_at IS NULL AND NOT EXISTS (SELECT 1 FROM availabilities a WHERE a.available_id = i.id AND a.available_type = 'Item')") || 0 }
      data << { title: "Durée moy. dispo (heures)", value: sql_value("SELECT ROUND(AVG(TIMESTAMPDIFF(HOUR, a.start_at, a.end_at)), 1) FROM availabilities a WHERE a.available_type = 'Item' AND a.end_at IS NOT NULL") || "N/A" }
      data << { title: "Dispos ouvertes (sans fin)", value: sql_value("SELECT COUNT(*) FROM availabilities a WHERE a.available_type = 'Item' AND a.end_at IS NULL") || 0 }
      data << { title: "Total fenêtres dispo", value: sql_value("SELECT COUNT(*) FROM availabilities a WHERE a.available_type = 'Item'") || 0 }

      # Globaux
      data << { title: "Items actifs", value: sql_value("SELECT COUNT(*) FROM items WHERE deleted_at IS NULL") || 0 }
      data << { title: "Items archivés", value: sql_value("SELECT COUNT(*) FROM items WHERE deleted_at IS NOT NULL") || 0 }

      render_success(data: data)
    end

    # GET /api/items/:id
    def show
      render_success(data: item_json(@item), errors: [])
    end

    # POST /api/items
    def create
      item = Item.new(item_params)

      if item.save
        render_success(data: item_json(item), errors: [])
      else
        render_error(item.errors.full_messages)
      end
    end

    # PATCH/PUT /api/items/:id
    def update
      if @item.update(item_params)
        render_success(data: item_json(@item), errors: [])
      else
        render_error(@item.errors.full_messages)
      end
    end

    # DELETE /api/items/:id (soft delete)
    def destroy
      archived_item = @item.soft_delete!

      render_success(data: item_json(archived_item), errors: [])
    end

    # DELETE /api/items/:id/hard (hard delete)
    def hard_destroy
      if @item.order_lines.any? || @item.combo_items.any?
        render_error(I18n.t("controllers.items.cannot_hard_delete"))
        return
      end

      item_data = item_json(@item)
      @item.destroy

      render_success(data: item_data, errors: [])
    end

    # PATCH /api/items/:id/restore
    def restore
      @item.update(deleted_at: nil)

      render_success(data: item_json(@item), errors: [])
    end

    private

    def set_item
      @item = Item.where(id: params[:id]).first!
    end

    def reject_if_archived
      return unless @item.deleted_at.present?

      render_error(I18n.t("controllers.items.cannot_update_archived"))
    end

    def set_item_unscoped
      @item = Item.unscoped.find(params[:id])
    end

    def item_params
      params.require(:item).permit(:name, :description, :price, :category_id, :image)
    end

    def sql_value(query)
      ActiveRecord::Base.connection.exec_query(query).rows.dig(0, 0)
    end

    def format_money(val)
      return "0.00 $" unless val

      format("%.2f $", val.to_f)
    end

    def item_json(item)
      item.as_json(
        only: %i[id name description price category_id deleted_at created_at],
        methods: %i[category_name image_url in_use],
        include: { availabilities: { only: %i[id start_at end_at description] } }
      )
    end
  end
end
