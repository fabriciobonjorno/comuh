# frozen_string_literal: true

class MessagesController < ApplicationController
  def show
    @message = Message.includes(:user, :reactions).find(params[:id])
    @replies = @message.replies.includes(:user, :reactions).order(:created_at)
  end
end
