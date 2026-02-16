module Api
  class TablesController < ApplicationController
    def show
      table = Table.find_by(temporary_code: params[:qr_token])

      if table.nil?
        render json: {
          success: false,
          data: nil,
          errors: ['Table introuvable. QR code invalide.']
        }, status: :not_found
        return
      end

      render json: {
        success: true,
        data: table_json(table),
        errors: []
      }, status: :ok
    end

    def index
      tables = Table.all.order(:number)

      render json: {
        success: true,
        data: tables.map { |t| table_json(t) },
        errors: []
      }, status: :ok
    end

    def create
      table = Table.new(table_params)
      table.temporary_code = SecureRandom.hex(16)

      if table.save
        render json: {
          success: true,
          data: table_json(table),
          errors: []
        }, status: :created
      else
        render json: {
          success: false,
          data: nil,
          errors: table.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    def qr_code
      table = Table.find_by(temporary_code: params[:qr_token])

      if table.nil?
        render json: {
          success: false,
          data: nil,
          errors: ['Table introuvable.']
        }, status: :not_found
        return
      end

      qr_url = "#{request.base_url}/table/#{table.temporary_code}"
      qrcode = RQRCode::QRCode.new(qr_url)
      svg = qrcode.as_svg(
        color: "1B1A17",
        shape_rendering: "crispEdges",
        module_size: 6,
        standalone: true,
        use_path: true
      )

      render json: {
        success: true,
        data: {
          table_number: table.number,
          qr_url: qr_url,
          svg: svg
        },
        errors: []
      }, status: :ok
    end

    private

    def table_params
      params.require(:table).permit(:number, :nb_seats)
    end

    def table_json(table)
      {
        id: table.id,
        number: table.number,
        capacity: table.nb_seats,
        status: table.orders.where(ended_at: nil).any? ? 'occupied' : 'available',
        qr_token: table.temporary_code
      }
    end
  end
end
