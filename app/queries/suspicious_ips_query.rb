# frozen_string_literal: true

class SuspiciousIpsQuery < ApplicationQuery
  def initialize(min_users: 3)
    @min_users = min_users
  end

  def call
    results = Message
      .joins(:user)
      .select(
        "messages.user_ip AS ip",
        "COUNT(DISTINCT messages.user_id) AS user_count",
        "ARRAY_AGG(DISTINCT users.username) AS usernames"
      )
      .group("messages.user_ip")
      .having("COUNT(DISTINCT messages.user_id) >= ?", @min_users)
      .order("user_count DESC")

    results.map do |r|
      {
        ip: r.ip,
        user_count: r.user_count.to_i,
        usernames: r.usernames
      }
    end
  end
end
