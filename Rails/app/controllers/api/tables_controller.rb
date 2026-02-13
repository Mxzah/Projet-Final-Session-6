module Api
  class TablesController < ApplicationController
    def show
      table = Table.find_by(qr_token: params[:qr_token])

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
        data: {
          id: table.id,
          number: table.number,
          capacity: table.capacity,
          status: table.status,
          qr_token: table.qr_token
        },
        errors: []
      }, status: :ok
    end

    def index
      tables = Table.all.order(:number)

      render json: {
        success: true,
        data: tables.map { |t|
          {
            id: t.id,
            number: t.number,
            capacity: t.capacity,
            status: t.status,
            qr_token: t.qr_token
          }
        },
        errors: []
      }, status: :ok
    end

    def create
      table = Table.new(table_params)

      if table.save
        render json: {
          success: true,
          data: {
            id: table.id,
            number: table.number,
            capacity: table.capacity,
            status: table.status,
            qr_token: table.qr_token
          },
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
      table = Table.find_by(qr_token: params[:qr_token])

      if table.nil?
        render json: {
          success: false,
          data: nil,
          errors: ['Table introuvable.']
        }, status: :not_found
        return
      end

      qr_url = "#{request.base_url}/table/#{table.qr_token}"
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
      params.require(:table).permit(:number, :capacity)
    end
  end
end
