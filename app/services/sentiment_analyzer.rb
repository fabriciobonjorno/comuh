# frozen_string_literal: true

class SentimentAnalyzer
  POSITIVE_WORDS = %w[ótimo excelente legal bom adorei incrível great good awesome amazing love nice].freeze
  NEGATIVE_WORDS = %w[ruim péssimo horrível terrível odeio terrible awful hate bad].freeze

  def self.call(text)
    text = text.to_s.downcase

    positive = POSITIVE_WORDS.count { |word| text.include?(word) }
    negative = NEGATIVE_WORDS.count { |word| text.include?(word) }

    total = positive + negative
    raw   = total.zero? ? 0.0 : ((positive - negative).to_f / total).round(2)

    SentimentScore.new(raw)
  end
end
