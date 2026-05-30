# frozen_string_literal: true

FactoryBot.define do
  factory :community do
    name { Faker::Internet.unique.slug }
    description { Faker::Lorem.sentence }

    trait :deleted do
      deleted_at { Time.current }
    end
  end
end
