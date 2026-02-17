module Api
  class WaitersController < ApplicationController
    before_action :authenticate_user!

    # GET /api/waiters/assigned
    def assigned
      waiter = Waiter.where(status: 'active').order('RAND()').first

      if waiter
        render json: {
          success: true,
          data: [{ id: waiter.id, name: "#{waiter.first_name} #{waiter.last_name}" }],
          error: [],
          errors: []
        }, status: :ok
      else
        render json: {
          success: true,
          data: [],
          error: [],
          errors: []
        }, status: :ok
      end
    end
  end
end
