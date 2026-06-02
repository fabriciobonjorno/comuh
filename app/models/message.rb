# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :user
  belongs_to :community
  belongs_to :parent_message, class_name: "Message", optional: true, inverse_of: :replies
  has_many :replies, class_name: "Message", foreign_key: :parent_message_id, dependent: :destroy, inverse_of: :parent_message
  has_many :reactions, dependent: :destroy

  before_validation :ensure_ai_sentiment_score
  after_create_commit :broadcast_created_message

  validates :user, :community, :content, :user_ip, :ai_sentiment_score, presence: true
  validates :ai_sentiment_score, numericality: { greater_than_or_equal_to: -1.0, less_than_or_equal_to: 1.0 }

  def sentiment_score
    SentimentScore.new(ai_sentiment_score)
  end

  def reaction_counts
    counts = reactions.group(:reaction_type).count
    Reaction::TYPES.index_with { |type| counts[type] || 0 }
  end

  private

  def ensure_ai_sentiment_score
    return if ai_sentiment_score.present? || content.blank?

    self.ai_sentiment_score = SentimentAnalyzer.call(content).to_f
  end

  def broadcast_created_message
    if parent_message.present?
      broadcast_append_to(
        parent_message,
        :replies,
        target: "replies",
        renderable: MessageComponent.new(message: self, show_thread_link: false)
      )
      broadcast_parent_reply_count
    else
      broadcast_prepend_to(
        community,
        :messages,
        target: "messages",
        renderable: MessageComponent.new(message: self, show_thread_link: true)
      )
    end
  rescue StandardError => error
    Rails.logger.error("Message broadcast failed for #{id}: #{error.class} - #{error.message}")
  end

  def broadcast_parent_reply_count
    parent_message.broadcast_replace_to(
      community,
      :messages,
      target: ActionView::RecordIdentifier.dom_id(parent_message),
      renderable: MessageComponent.new(message: parent_message, show_thread_link: true)
    )

    parent_message.broadcast_replace_to(
      parent_message,
      :thread,
      target: ActionView::RecordIdentifier.dom_id(parent_message),
      renderable: MessageComponent.new(message: parent_message, show_thread_link: false)
    )
  rescue StandardError => error
    Rails.logger.error("Parent reply count broadcast failed for #{parent_message_id}: #{error.class} - #{error.message}")
  end
end
