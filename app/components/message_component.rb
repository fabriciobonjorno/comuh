# frozen_string_literal: true

class MessageComponent < ApplicationComponent
  def initialize(message:, show_thread_link: true)
    @message = message
    @show_thread_link = show_thread_link
  end

  def avatar_initials
    @message.user.username.first(2).upcase
  end

  def replies_count
    @message.replies.size
  end
end
