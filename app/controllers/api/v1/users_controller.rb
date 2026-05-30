# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      def create
        user = ::Users::Create.call(user_params)
        render json: user.as_json(only: %i[id username]), status: :created
      end

      private

      def user_params
        permitted = %i[username]

        if params[:user].present?
          params.require(:user).permit(permitted)
        else
          params.permit(permitted)
        end
      end
    end
  end
end
