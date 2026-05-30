# frozen_string_literal: true

module Api
  module V1
    class CommunitiesController < BaseController
      def create
        community = ::Communities::Create.call(community_params)
        render json: community.as_json(only: %i[id name description]), status: :created
      end

      private

      def community_params
        permitted = %i[name description]

        if params[:community].present?
          params.require(:community).permit(permitted)
        else
          params.permit(permitted)
        end
      end
    end
  end
end
