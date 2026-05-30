# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :user
  belongs_to :community
  belongs_to :parent_message, class_name: "Message", optional: true, inverse_of: :replies
  has_many :replies, class_name: "Message", foreign_key: :parent_message_id, dependent: :destroy, inverse_of: :parent_message

  before_validation :ensure_ai_sentiment_score

  validates :user, :community, :content, :user_ip, :ai_sentiment_score, presence: true
  validates :ai_sentiment_score, numericality: { greater_than_or_equal_to: -1.0, less_than_or_equal_to: 1.0 }

  def sentiment_score
    SentimentScore.new(ai_sentiment_score)
  end

  private

  def ensure_ai_sentiment_score
    return if ai_sentiment_score.present? || content.blank?

    self.ai_sentiment_score = SentimentAnalyzer.call(content).to_f
  end
end
