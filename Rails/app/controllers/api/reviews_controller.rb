# frozen_string_literal: true

module Api
  # CRUD and soft-delete operations for reviews
  class ReviewsController < ApplicationController
    include StatsReportable

    before_action :authenticate_unless_public
    skip_before_action :check_session_expiry, only: [:for_reviewable]
    before_action :set_review, only: %i[show update destroy]

    # GET /api/reviews/stats
    def stats
      unless current_user.is_a?(Administrator)
        return render json: { success: false, data: nil, errors: ["Accès refusé"] }, status: :ok
      end

      super
    end

    # GET /api/reviews/for_reviewable?reviewable_type=Item&reviewable_id=5
    # Public endpoint — returns active reviews for a specific item/combo/server
    def for_reviewable
      reviews = Review.active
                      .where(reviewable_type: params[:reviewable_type], reviewable_id: params[:reviewable_id])
                      .order(created_at: :desc)
                      .limit(20)

      avg = reviews.average(:rating)&.round(1) || 0
      count = reviews.count

      render json: {
        success: true,
        data: {
          average_rating: avg.to_f,
          review_count: count,
          reviews: reviews.map { |r| review_json(r) }
        },
        errors: []
      }, status: :ok
    end

    # GET /api/reviews?search=…&reviewable_type=…&rating=…&sort=…&status=…
    def index
      reviews = if current_user.is_a?(Administrator)
                  Review.all
      else
                  Review.where(user_id: current_user.id)
      end

      # Status filter (active / deleted / all)
      case params[:status]
      when "active"
        reviews = reviews.active
      when "deleted"
        reviews = reviews.where.not(deleted_at: nil)
        # else: return all (admin and client both see deleted reviews)
      end

      # Search (admin only — by user name or comment)
      if params[:search].present? && current_user.is_a?(Administrator)
        reviews = reviews.joins("INNER JOIN users ON users.id = reviews.user_id")
                         .where(
                           "users.first_name LIKE ? OR users.last_name LIKE ? OR reviews.comment LIKE ?",
                           "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"
                         )
      end

      # Filter by reviewable_type (supports comma-separated for multi-select)
      if params[:reviewable_type].present?
        types = params[:reviewable_type].split(",")
        reviews = reviews.where(reviewable_type: types)
      end

      # Filter by rating (supports comma-separated for multi-select)
      if params[:rating].present?
        ratings = params[:rating].split(",").map(&:to_i)
        reviews = reviews.where(rating: ratings)
      end

      # Sort
      reviews = case params[:sort]
      when "oldest"
                  reviews.order(created_at: :asc)
      when "rating_high"
                  reviews.order(rating: :desc)
      when "rating_low"
                  reviews.order(rating: :asc)
      else
                  reviews.order(created_at: :desc)
      end

      render json: {
        success: true,
        data: reviews.map { |r| review_json(r) },
        errors: []
      }, status: :ok
    end

    # GET /api/reviews/:id
    def show
      unless current_user.is_a?(Administrator) || @review.user_id == current_user.id
        return render json: { success: false, data: nil, errors: [ I18n.t("controllers.reviews.unauthorized") ] },
                      status: :ok
      end

      render json: {
        success: true,
        data: review_json(@review),
        errors: []
      }, status: :ok
    end

    # POST /api/reviews
    def create
      unless current_user.can_review?
        return render json: { success: false, data: nil, errors: [ I18n.t("controllers.reviews.only_clients") ] },
                      status: :ok
      end

      permitted = review_params
      images = permitted.delete(:images)
      review = Review.new(permitted)
      review.user_id = current_user.id

      if review.save
        review.images.attach(images) if images.present?
        render json: {
          success: true,
          data: review_json(review),
          errors: []
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: review.errors.full_messages
        }, status: :ok
      end
    end

    # PATCH/PUT /api/reviews/:id
    def update
      unless current_user.can_review? || current_user.is_a?(Administrator)
        return render json: { success: false, data: nil, errors: [ I18n.t("controllers.reviews.only_clients") ] },
                      status: :ok
      end

      unless @review.user_id == current_user.id
        return render json: { success: false, data: nil, errors: [ I18n.t("controllers.reviews.update_own_only") ] },
                      status: :ok
      end

      permitted = review_update_params
      images = permitted.delete(:images)
      remove_ids = permitted.delete(:remove_image_ids)
      if @review.update(permitted)
        if remove_ids.present?
          remove_ids.each do |signed_id|
            attachment = @review.images.find { |img| img.signed_id == signed_id }
            attachment&.purge
          end
          @review.reload
        end
        @review.images.attach(images) if images.present?
        render json: {
          success: true,
          data: review_json(@review.reload),
          errors: []
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: @review.errors.full_messages
        }, status: :ok
      end
    end

    # DELETE /api/reviews/:id (soft delete)
    def destroy
      unless current_user.is_a?(Administrator) || @review.user_id == current_user.id
        return render json: { success: false, data: nil, errors: [ I18n.t("controllers.reviews.unauthorized") ] },
                      status: :ok
      end

      reason = current_user.is_a?(Administrator) ? params[:reason] : nil
      @review.soft_delete!(reason: reason)

      render json: {
        success: true,
        data: nil,
        errors: []
      }, status: :ok
    end

    private

    def render_success(attributes = {})
      render json: { success: true }.merge(attributes), status: :ok
    end

    def render_error(errors)
      errors = [errors] unless errors.is_a?(Array)
      render json: { success: false, errors: errors }, status: :ok
    end

    def authenticate_unless_public
      return if action_name == "for_reviewable"

      authenticate_user!
    end

    def set_review
      @review = Review.find_by(id: params[:id])
      return if @review

      render json: { success: false, data: nil, errors: [ I18n.t("controllers.reviews.not_found") ] }, status: :ok
    end

    def stats_config
      {
        columns: [
          { key: "reviewable_label", label: "Élément" },
          { key: "reviewable_type", label: "Type" },
          { key: "nb_reviews", label: "Nb avis" },
          { key: "min_rating", label: "Note min" },
          { key: "max_rating", label: "Note max" },
          { key: "avg_rating", label: "Note moy." },
          { key: "with_comment", label: "Avec commentaire" },
          { key: "with_images", label: "Avec images" },
          { key: "reviewers", label: "Nb ayant évalué" },
          { key: "total_users", label: "Nb ayant commandé" },
          { key: "review_pct", label: "% évaluation" }
        ],
        category_column: "r.reviewable_type",
        category_strings: true,
        base_conditions: ["r.deleted_at IS NULL"],
        sql: ->(where_clause, extra) {
          sd = extra[:start_date].present? ? ActiveRecord::Base.connection.quote(extra[:start_date]) : nil
          ed = extra[:end_date].present? ? ActiveRecord::Base.connection.quote(extra[:end_date]) : nil

          date_cond = ""
          date_cond += " AND r.created_at >= #{sd}" if sd
          date_cond += " AND r.created_at <= #{ed}" if ed

          # Date condition for order-based user counts
          order_date_cond = ""
          order_date_cond += " AND o.created_at >= #{sd}" if sd
          order_date_cond += " AND o.created_at <= #{ed}" if ed

          # Rating filter (multi-select avg stars 1-5) via HAVING
          rating_having = ""
          if extra[:params][:rating_ids].present?
            ratings = Array(extra[:params][:rating_ids]).map(&:to_i).select { |r| r.between?(1, 5) }
            if ratings.any?
              rating_having = "HAVING ROUND(AVG(r.rating)) IN (#{ratings.join(', ')})"
            end
          end

          <<~SQL
            SELECT
              sub.reviewable_label,
              sub.reviewable_type_label AS reviewable_type,
              sub.nb_reviews,
              sub.min_rating,
              sub.max_rating,
              sub.avg_rating,
              sub.with_comment,
              sub.with_images,
              sub.reviewers,
              sub.total_users,
              CASE
                WHEN sub.total_users > 0
                THEN CONCAT(sub.reviewers, ' / ', sub.total_users, '  (', ROUND(sub.reviewers * 100.0 / sub.total_users), '%)')
                ELSE CONCAT(sub.reviewers, ' / 0')
              END AS review_pct
            FROM (
              SELECT
                CASE r.reviewable_type
                  WHEN 'User' THEN CONCAT(u_rev.first_name, ' ', u_rev.last_name)
                  WHEN 'Item' THEN i_rev.name
                  WHEN 'Combo' THEN c_rev.name
                END AS reviewable_label,
                CASE r.reviewable_type
                  WHEN 'User' THEN 'Serveur'
                  WHEN 'Item' THEN 'Item'
                  WHEN 'Combo' THEN 'Combo'
                END AS reviewable_type_label,
                r.reviewable_type AS raw_type,
                r.reviewable_id,
                COUNT(*) AS nb_reviews,
                MIN(r.rating) AS min_rating,
                MAX(r.rating) AS max_rating,
                CAST(ROUND(AVG(r.rating), 1) AS DOUBLE) AS avg_rating,
                SUM(CASE WHEN r.comment IS NOT NULL AND r.comment != '' THEN 1 ELSE 0 END) AS with_comment,
                SUM(CASE WHEN EXISTS (
                  SELECT 1 FROM active_storage_attachments asa
                  WHERE asa.record_type = 'Review' AND asa.record_id = r.id AND asa.name = 'images'
                ) THEN 1 ELSE 0 END) AS with_images,
                COUNT(DISTINCT r.user_id) AS reviewers,
                CASE r.reviewable_type
                  WHEN 'User' THEN (
                    SELECT COUNT(DISTINCT o.client_id)
                    FROM orders o
                    WHERE o.server_id = r.reviewable_id
                      AND o.deleted_at IS NULL
                      #{order_date_cond}
                  )
                  WHEN 'Item' THEN (
                    SELECT COUNT(DISTINCT o.client_id)
                    FROM order_lines ol
                    JOIN orders o ON o.id = ol.order_id AND o.deleted_at IS NULL
                    WHERE ol.orderable_type = 'Item' AND ol.orderable_id = r.reviewable_id
                      #{order_date_cond}
                  )
                  WHEN 'Combo' THEN (
                    SELECT COUNT(DISTINCT o.client_id)
                    FROM order_lines ol
                    JOIN orders o ON o.id = ol.order_id AND o.deleted_at IS NULL
                    WHERE ol.orderable_type = 'Combo' AND ol.orderable_id = r.reviewable_id
                      #{order_date_cond}
                  )
                END AS total_users
              FROM reviews r
              LEFT JOIN users u_rev ON r.reviewable_type = 'User' AND u_rev.id = r.reviewable_id
              LEFT JOIN items i_rev ON r.reviewable_type = 'Item' AND i_rev.id = r.reviewable_id
              LEFT JOIN combos c_rev ON r.reviewable_type = 'Combo' AND c_rev.id = r.reviewable_id
              #{where_clause}
              #{date_cond}
              GROUP BY r.reviewable_type, r.reviewable_id,
                       u_rev.first_name, u_rev.last_name, i_rev.name, c_rev.name
              #{rating_having}
            ) sub
            ORDER BY sub.nb_reviews DESC
          SQL
        }
      }
    end

    def review_params
      params.require(:review).permit(:rating, :comment, :reviewable_type, :reviewable_id, :order_id, images: [])
    end

    def review_update_params
      params.require(:review).permit(:rating, :comment, images: [], remove_image_ids: [])
    end

    def review_json(review)
      review.as_json
    end
  end
end
