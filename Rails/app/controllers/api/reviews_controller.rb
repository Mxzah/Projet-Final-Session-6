# frozen_string_literal: true

module Api
  # CRUD and soft-delete operations for reviews
  class ReviewsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_review, only: %i[show update destroy]

    # GET /api/reviews?search=…&reviewable_type=…&rating=…&sort=…&status=…
    def index
      reviews = if current_user.type == "Administrator"
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
      if params[:search].present? && current_user.type == "Administrator"
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
      unless current_user.type == "Administrator" || @review.user_id == current_user.id
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
      unless current_user.type == "Client"
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
      unless @review.user_id == current_user.id
        return render json: { success: false, data: nil, errors: [ I18n.t("controllers.reviews.update_own_only") ] },
                      status: :ok
      end

      permitted = review_update_params
      images = permitted.delete(:images)
      if @review.update(permitted)
        @review.images.attach(images) if images.present?
        render json: {
          success: true,
          data: review_json(@review),
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
      unless current_user.type == "Administrator" || @review.user_id == current_user.id
        return render json: { success: false, data: nil, errors: [ I18n.t("controllers.reviews.unauthorized") ] },
                      status: :ok
      end

      reason = current_user.type == "Administrator" ? params[:reason] : nil
      @review.soft_delete!(reason: reason)

      render json: {
        success: true,
        data: nil,
        errors: []
      }, status: :ok
    end

    private

    def set_review
      @review = Review.find_by(id: params[:id])
      return if @review

      render json: { success: false, data: nil, errors: [ I18n.t("controllers.reviews.not_found") ] }, status: :ok
    end

    def review_params
      params.require(:review).permit(:rating, :comment, :reviewable_type, :reviewable_id, :order_id, images: [])
    end

    def review_update_params
      params.require(:review).permit(:rating, :comment, images: [])
    end

    def review_json(review)
      review.as_json
    end
  end
end
