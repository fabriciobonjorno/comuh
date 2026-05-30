# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      skip_forgery_protection

      rescue_from ActiveRecord::RecordInvalid do |exception|
        render_error(exception.record.errors.full_messages.to_sentence, status: :unprocessable_content)
      end

      rescue_from ActiveRecord::RecordNotFound do |exception|
        code = exception.model == "User" ? "user_not_found" : "not_found"
        render json: { error: exception.message, code: code }, status: :not_found
      end

      rescue_from ActionController::ParameterMissing do |exception|
        render_error(exception.message, status: :bad_request)
      end

      rescue_from DuplicateReactionError do |exception|
        render_error(exception.message, status: :conflict)
      end

      private

      def render_error(message, status:)
        render json: { error: message }, status: status
      end
    end
  end
end
