# frozen_string_literal: true

class MessageSerializer
  def initialize(message)
    @message = message
  end

  def as_json(*)
    {
      id: @message.id,
      content: @message.content,
      user: {
        id: @message.user.id,
        username: @message.user.username
      },
      community_id: @message.community_id,
      parent_message_id: @message.parent_message_id,
      ai_sentiment_score: @message.ai_sentiment_score,
      created_at: @message.created_at
    }
  end
end
