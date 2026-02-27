module Api
  class UsersController < AdminController
    before_action :set_user, only: [ :show, :update, :destroy ]

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
      if params[:status].present?
        users = users.where(status: params[:status])
      end
      if params[:type].present?
        if User::VALID_TYPES.include?(params[:type])
          users = users.where(type: params[:type])
        else
          users = users.none
        end
      end

      # Sort
      sort_col = User::SORTABLE_COLUMNS.include?(params[:sort_by]) ? params[:sort_by] : "last_name"
      case params[:sort]
      when "asc"
        users = users.order(sort_col => :asc)
      when "desc"
        users = users.order(sort_col => :desc)
      else
        users = users.order(:last_name, :first_name)
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
          errors: [ "Cannot create Client users from admin panel" ]
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
        errors: [ "Type is not included in the list" ]
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
          errors: [ "You cannot modify your own account" ]
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
        errors: [ "Type is not included in the list" ]
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
          errors: [ "You cannot delete your own account" ]
        }, status: :ok
      end

      # Last admin protection
      if @user.type == "Administrator" && Administrator.where.not(id: @user.id).count == 0
        return render json: {
          success: false,
          data: nil,
          errors: [ "Cannot delete the last administrator" ]
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
      params.require(:user).permit(:email, :first_name, :last_name, :type, :status, :password, :password_confirmation, :block_note)
    end
  end
end
