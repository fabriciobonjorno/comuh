# frozen_string_literal: true

class CommunityMessagesQuery < ApplicationQuery
  def initialize(community)
    @community = community
  end

  def call
    @community
      .messages
      .where(parent_message_id: nil)
      .includes(:user, :reactions, :replies)
      .order(created_at: :desc)
      .limit(50)
  end
end
