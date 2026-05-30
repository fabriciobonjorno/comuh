# frozen_string_literal: true

class User < ApplicationRecord
  normalizes :username, with: -> { _1.strip.downcase }

  validates :username, presence: true,
                       format: { with: /\A[a-z0-9][a-z0-9_-]*\z/,
                                 message: :invalid_username },
                       uniqueness: { conditions: -> { where(deleted_at: nil) } }
end
