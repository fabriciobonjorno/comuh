# frozen_string_literal: true

module Api
  module V1
    module Communities
      class MessagesController < ApplicationController
        def top
          messages = TopMessagesQuery.call(
            community_id: params[:id],
            limit: params.fetch(:limit, 10).to_i.clamp(1, 50)
          )

          render json: { messages: messages }
        end
      end
    end
  end
end
