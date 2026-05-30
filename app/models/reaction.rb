# frozen_string_literal: true

class Reaction < ApplicationRecord
  TYPES = %w[like love insightful].freeze

  belongs_to :user
  belongs_to :message

  validates :user, :message, presence: true
  validates :reaction_type, presence: true, inclusion: { in: TYPES }
  validates :user_id, uniqueness: { scope: %i[message_id reaction_type] }
end
