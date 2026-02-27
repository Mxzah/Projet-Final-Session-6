module Api
  class ReviewsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_review, only: [:show, :update, :destroy]

    # GET /api/reviews?search=…&reviewable_type=…&rating=…&sort=…
    def index
      reviews = if current_user.type == "Administrator"
        Review.all
      else
        Review.where(user_id: current_user.id)
      end

      # Search (admin only — by user name or comment)
      if params[:search].present? && current_user.type == "Administrator"
        reviews = reviews.joins("INNER JOIN users ON users.id = reviews.user_id")
                         .where(
                           "users.first_name LIKE ? OR users.last_name LIKE ? OR reviews.comment LIKE ?",
                           "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"
                         )
      end

      # Filter by reviewable_type
      if params[:reviewable_type].present?
        reviews = reviews.where(reviewable_type: params[:reviewable_type])
      end

      # Filter by rating
      if params[:rating].present?
        reviews = reviews.where(rating: params[:rating])
      end

      # Sort
      case params[:sort]
      when "oldest"
        reviews = reviews.order(created_at: :asc)
      when "rating_high"
        reviews = reviews.order(rating: :desc)
      when "rating_low"
        reviews = reviews.order(rating: :asc)
      else
        reviews = reviews.order(created_at: :desc)
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
        return render json: { success: false, data: nil, errors: ["Unauthorized"] }, status: :ok
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
        return render json: { success: false, data: nil, errors: ["Only clients can create reviews"] }, status: :ok
      end

      review = Review.new(review_params)
      review.user_id = current_user.id

      if review.save
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
        return render json: { success: false, data: nil, errors: ["You can only update your own reviews"] }, status: :ok
      end

      if @review.update(review_update_params)
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
        return render json: { success: false, data: nil, errors: ["Unauthorized"] }, status: :ok
      end

      @review.soft_delete!

      render json: {
        success: true,
        data: nil,
        errors: []
      }, status: :ok
    end

    private

    def set_review
      @review = Review.find_by(id: params[:id])
      unless @review
        render json: { success: false, data: nil, errors: ["Review not found"] }, status: :ok
      end
    end

    def review_params
      params.require(:review).permit(:rating, :comment, :reviewable_type, :reviewable_id)
    end

    def review_update_params
      params.require(:review).permit(:rating, :comment)
    end

    def review_json(review)
      review.as_json
    end
  end
end
