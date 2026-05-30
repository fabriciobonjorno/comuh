# frozen_string_literal: true

class SentimentBadgeComponent < ApplicationComponent
  def initialize(score:)
    @score = score.is_a?(SentimentScore) ? score : SentimentScore.new(score)
  end

  def label         = @score.label
  def emoji         = @score.emoji
  def badge_classes = @score.badge_css_classes
end
