# frozen_string_literal: true

module Api
  module V1
    class MessagesController < BaseController
      def create
        payload = message_params.to_h.deep_symbolize_keys
        payload[:user_ip] ||= request.remote_ip

        message = Messages::Create.call(payload)
        show_thread_link = payload[:parent_message_id].blank?
        response_body = MessageSerializer.new(message).as_json.merge(
          html: render_to_string(MessageComponent.new(message: message, show_thread_link: show_thread_link), layout: false, formats: [ :html ])
        )

        respond_to do |format|
          format.json { render json: response_body, status: :created }
          format.html { render html: response_body[:html].html_safe, status: :created }
          format.turbo_stream do
            if params[:target_id].present?
              render turbo_stream: turbo_stream.append(params[:target_id], MessageComponent.new(message: message, show_thread_link: show_thread_link))
            else
              render html: response_body[:html].html_safe, status: :created
            end
          end
        end
      end

      private

      def message_params
        permitted = %i[user_id username community_id content user_ip parent_message_id]

        root_params = params.permit(permitted).to_h
        nested_params = params[:message].present? ? params.require(:message).permit(permitted).to_h : {}

        root_params.merge(nested_params)
      end
    end
  end
end
