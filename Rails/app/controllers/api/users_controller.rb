# frozen_string_literal: true

module Api
  # User management for administrators
  class UsersController < AdminController
    before_action :set_user, only: %i[show update destroy]

    # GET /api/users?search=…&sort=asc|desc&sort_by=…&status=…&type=…
    def index
      users = User.all

      # Search
      if params[:search].present?
        users = users.where(
          "users.first_name LIKE ? OR users.last_name LIKE ? OR users.email LIKE ?",
          "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"
        )
      end

      # Filter
      users = users.where(status: params[:status]) if params[:status].present?
      if params[:type].present?
        users = if User::VALID_TYPES.include?(params[:type])
                  users.where(type: params[:type])
        else
                  users.none
        end
      end

      # Sort
      sort_col = User::SORTABLE_COLUMNS.include?(params[:sort_by]) ? params[:sort_by] : "last_name"
      users = case params[:sort]
      when "asc"
                users.order(sort_col => :asc)
      when "desc"
                users.order(sort_col => :desc)
      else
                users.order(:last_name, :first_name)
      end

      render json: {
        success: true,
        data: users.map(&:as_json),
        errors: []
      }, status: :ok
    end

    # GET /api/users/:id
    def show
      render json: {
        success: true,
        data: @user.as_json,
        errors: []
      }, status: :ok
    end

    # POST /api/users
    def create
      # Block creating Client type via admin CRUDL
      if user_params[:type] == "Client"
        return render json: {
          success: false,
          data: nil,
          errors: [ I18n.t("controllers.users.cannot_create_client") ]
        }, status: :ok
      end

      user = User.new(user_params)

      if user.save
        render json: {
          success: true,
          data: user.as_json,
          errors: []
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: user.errors.full_messages
        }, status: :ok
      end
    rescue ActiveRecord::SubclassNotFound
      render json: {
        success: false,
        data: nil,
        errors: [ I18n.t("controllers.users.type_invalid") ]
      }, status: :ok
    rescue ArgumentError => e
      render json: {
        success: false,
        data: nil,
        errors: [ e.message ]
      }, status: :ok
    end

    # PATCH/PUT /api/users/:id
    def update
      # Self-update protection
      if @user.id == current_user.id
        return render json: {
          success: false,
          data: nil,
          errors: [ I18n.t("controllers.users.cannot_modify_self") ]
        }, status: :ok
      end

      if @user.update(user_params)
        render json: {
          success: true,
          data: @user.as_json,
          errors: []
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: @user.errors.full_messages
        }, status: :ok
      end
    rescue ActiveRecord::SubclassNotFound
      render json: {
        success: false,
        data: nil,
        errors: [ I18n.t("controllers.users.type_invalid") ]
      }, status: :ok
    rescue ArgumentError => e
      render json: {
        success: false,
        data: nil,
        errors: [ e.message ]
      }, status: :ok
    end

    # DELETE /api/users/:id (soft delete)
    def destroy
      # Self-delete protection
      if @user.id == current_user.id
        return render json: {
          success: false,
          data: nil,
          errors: [ I18n.t("controllers.users.cannot_delete_self") ]
        }, status: :ok
      end

      # Last admin protection
      if @user.type == "Administrator" && Administrator.where.not(id: @user.id).count.zero?
        return render json: {
          success: false,
          data: nil,
          errors: [ I18n.t("controllers.users.cannot_delete_last_admin") ]
        }, status: :ok
      end

      @user.soft_delete!

      render json: {
        success: true,
        data: nil,
        errors: []
      }, status: :ok
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email, :first_name, :last_name, :type, :status, :password, :password_confirmation,
                                   :block_note)
    end
  end
end
