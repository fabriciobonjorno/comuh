# frozen_string_literal: true

class DuplicateReactionError < StandardError
  def initialize(msg = "Reaction already exists")
    super
  end
end
