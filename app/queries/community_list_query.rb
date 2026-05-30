# frozen_string_literal: true

class CommunityListQuery < ApplicationQuery
  def call
    Community
      .left_joins(:messages)
      .select("communities.*, COUNT(messages.id) AS messages_count")
      .group("communities.id")
      .order(:name)
  end
end
