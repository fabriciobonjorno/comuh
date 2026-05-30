# frozen_string_literal: true

class Community < ApplicationRecord
  normalizes :name, with: -> { _1.strip }

  has_many :messages, dependent: :destroy

  validates :name, presence: true,
                   uniqueness: { conditions: -> { where(deleted_at: nil) } }
end
