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
        valid_types = %w[Administrator Waiter Client Cook]
        if valid_types.include?(params[:type])
          users = users.where(type: params[:type])
        else
          users = users.none
        end
      end

      # Sort
      sort_column = %w[first_name last_name email created_at].include?(params[:sort_by]) ? params[:sort_by] : "last_name"
      case params[:sort]
      when "asc"
        users = users.order(sort_column => :asc)
      when "desc"
        users = users.order(sort_column => :desc)
      else
        users = users.order(:last_name, :first_name)
      end

      render json: {
        success: true,
        data: users.map { |u| user_json(u) },
        errors: []
      }, status: :ok
    end

    # GET /api/users/:id
    def show
      render json: {
        success: true,
        data: user_json(@user),
        errors: []
      }, status: :ok
    end

    # POST /api/users
    def create
      user = User.new(user_params)

      if user.save
        render json: {
          success: true,
          data: user_json(user),
          errors: []
        }, status: :created
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
    end

    # PATCH/PUT /api/users/:id
    def update
      update_data = user_params
      # Strip blank passwords so update without password change works
      if update_data[:password].blank?
        update_data.delete(:password)
        update_data.delete(:password_confirmation)
      end

      if @user.update(update_data)
        render json: {
          success: true,
          data: user_json(@user),
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
    end

    # DELETE /api/users/:id (soft delete)
    def destroy
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
      params.require(:user).permit(:email, :first_name, :last_name, :type, :status, :password, :password_confirmation)
    end

    def user_json(user)
      {
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        type: user.type,
        status: user.status,
        created_at: user.created_at
      }
    end
  end
end
