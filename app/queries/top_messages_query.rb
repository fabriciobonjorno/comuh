# frozen_string_literal: true

class TopMessagesQuery < ApplicationQuery
  def initialize(community_id:, limit: 10)
    @community_id = community_id
    @limit        = limit
  end

  def call
    results = Message
      .joins(:user)
      .joins("LEFT JOIN reactions ON reactions.message_id = messages.id")
      .joins("LEFT JOIN messages replies ON replies.parent_message_id = messages.id")
      .where(messages: { community_id: @community_id, parent_message_id: nil })
      .select(
        "messages.id",
        "messages.content",
        "messages.ai_sentiment_score",
        "users.id AS user_id",
        "users.username",
        "COUNT(DISTINCT reactions.id) AS reaction_count",
        "COUNT(DISTINCT replies.id) AS reply_count",
        "(COUNT(DISTINCT reactions.id) * 1.5 + COUNT(DISTINCT replies.id) * 1.0) AS engagement_score"
      )
      .group("messages.id, users.id")
      .order("engagement_score DESC")
      .limit(@limit)

    results.map do |m|
      {
        id: m.id,
        content: m.content,
        user: { id: m.user_id, username: m.username },
        ai_sentiment_score: m.ai_sentiment_score,
        reaction_count: m.reaction_count.to_i,
        reply_count: m.reply_count.to_i,
        engagement_score: m.engagement_score.to_f
      }
    end
  end
end
