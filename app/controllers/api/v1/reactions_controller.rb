# frozen_string_literal: true

module Api
  module V1
    class ReactionsController < BaseController
      def create
        payload = reaction_params.to_h
        counts = Reactions::Create.call(payload)

        render json: {
          message_id: payload[:message_id],
          reactions: {
            like:       counts["like"] || 0,
            love:       counts["love"] || 0,
            insightful: counts["insightful"] || 0
          }
        }
      end

      private

      def reaction_params
        permitted = %i[message_id user_id username reaction_type]

        payload = params.permit(permitted).to_h.symbolize_keys
        if params[:reaction].present?
          payload.merge!(params.require(:reaction).permit(permitted).to_h.symbolize_keys)
        end

        payload
      end
    end
  end
end
