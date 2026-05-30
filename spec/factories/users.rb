# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user_#{n}" }

    trait :deleted do
      deleted_at { Time.current }
    end
  end
end
