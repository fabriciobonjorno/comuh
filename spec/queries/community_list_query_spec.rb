# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommunityListQuery do
  describe ".call" do
    it "returns communities ordered by name with messages count" do
      community_a = create(:community, name: "Alpha")
      community_b = create(:community, name: "Beta")

      create(:message, community: community_b)
      create(:message, community: community_b)

      results = described_class.call

      expect(results.map(&:name)).to eq([ "Alpha", "Beta" ])
      expect(results.find { |community| community.id == community_b.id }.messages_count).to eq(2)
      expect(results.find { |community| community.id == community_a.id }.messages_count).to eq(0)
    end
  end
end
