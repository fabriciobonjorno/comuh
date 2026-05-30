# frozen_string_literal: true

require "rails_helper"

RSpec.describe TopMessagesQuery do
  let(:community) { create(:community) }

  describe ".call" do
    it "returns an array" do
      expect(described_class.call(community_id: community.id)).to be_an(Array)
    end

    it "returns messages with expected keys" do
      create(:message, community: community)
      result = described_class.call(community_id: community.id).first
      expect(result.keys).to include(:id, :content, :user, :ai_sentiment_score,
                                     :reaction_count, :reply_count, :engagement_score)
    end

    it "orders by engagement score descending" do
      low  = create(:message, community: community)
      high = create(:message, community: community)
      3.times { create(:reaction, message: high) }
      1.times { create(:reaction, message: low) }

      results = described_class.call(community_id: community.id)
      expect(results.first[:id]).to eq(high.id)
    end

    it "calculates engagement score as (reactions * 1.5) + replies" do
      msg = create(:message, community: community)
      2.times { create(:reaction, message: msg) }
      create(:message, community: community, parent_message_id: msg.id)

      result = described_class.call(community_id: community.id).find { |m| m[:id] == msg.id }
      expect(result[:engagement_score]).to eq(2 * 1.5 + 1.0)
    end

    it "respects the limit param" do
      5.times { create(:message, community: community) }
      expect(described_class.call(community_id: community.id, limit: 2).size).to eq(2)
    end

    it "only includes top-level messages (no replies)" do
      parent_message = create(:message, community: community)
      create(:message, community: community, parent_message_id: parent_message.id)

      results = described_class.call(community_id: community.id)
      expect(results.map { |m| m[:id] }).to include(parent_message.id)
      expect(results.size).to eq(1)
    end
  end
end
