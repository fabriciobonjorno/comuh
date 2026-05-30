# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  #allow_browser versions: :modern if Rails.env.production?

  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_to do |format|
      format.html { redirect_to root_path, alert: "#{e.model} not found." }
      format.json { render json: { error: e.message }, status: :not_found }
    end
  end
end
