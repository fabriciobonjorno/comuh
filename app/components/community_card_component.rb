# frozen_string_literal: true

class CommunityCardComponent < ApplicationComponent
  def initialize(community:)
    @community = community
  end

  def messages_count
    @community.try(:messages_count) || @community.messages.count
  end
end
