# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    association :user
    association :community
    parent_message { nil }
    content { Faker::Lorem.sentence }
    user_ip { Faker::Internet.ip_v4_address }
    ai_sentiment_score { SentimentAnalyzer.call(content).to_f }

    trait :with_sentiment do
      ai_sentiment_score { rand(-1.0..1.0).round(4) }
    end

    trait :reply do
      association :parent_message, factory: :message
    end
  end
end
