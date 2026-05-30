# frozen_string_literal: true

# Value Object that wraps a raw sentiment float and provides
# domain-meaningful accessors (label, emoji, CSS classes).
# Includes Comparable so it can be compared directly to numbers,
# keeping existing specs that do `score > 0` working transparently.
class SentimentScore
  include Comparable

  POSITIVE_THRESHOLD =  0.1
  NEGATIVE_THRESHOLD = -0.1

  attr_reader :value

  def initialize(value)
    @value = value.to_f.clamp(-1.0, 1.0)
  end

  # Comparable — allows `score > 0`, `score.between?(-1, 1)`, `score == 0.0`
  def <=>(other)
    @value <=> other.to_f
  end

  def to_f = @value
  def to_s = @value.to_s

  def label
    positive? ? "Positive" : negative? ? "Negative" : "Neutral"
  end

  def emoji
    positive? ? "😊" : negative? ? "😡" : "😐"
  end

  def badge_css_classes
    if positive?
      "bg-green-100 text-green-700 ring-green-600/20"
    elsif negative?
      "bg-red-100 text-red-700 ring-red-600/20"
    else
      "bg-gray-100 text-gray-600 ring-gray-500/10"
    end
  end

  def positive? = @value > POSITIVE_THRESHOLD
  def negative? = @value < NEGATIVE_THRESHOLD
  def neutral?  = !positive? && !negative?
end
