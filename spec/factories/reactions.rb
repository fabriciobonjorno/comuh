# frozen_string_literal: true

FactoryBot.define do
  factory :reaction do
    association :user
    association :message
    reaction_type { Reaction::TYPES.sample }
  end
end
