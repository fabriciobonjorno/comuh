# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/v1/communities/:id/messages/top", type: :request do
  let(:community) { create(:community) }

  it "returns 200" do
    get messages_top_api_v1_community_path(community)
    expect(response).to have_http_status(:ok)
  end

  it "returns a messages array" do
    create(:message, community: community)
    get messages_top_api_v1_community_path(community)
    expect(response.parsed_body["messages"]).to be_an(Array)
  end

  it "includes engagement data for each message" do
    create(:message, community: community)
    get messages_top_api_v1_community_path(community)
    msg = response.parsed_body["messages"].first
    expect(msg).to include("id", "content", "engagement_score")
  end

  it "respects the limit param" do
    5.times { create(:message, community: community) }
    get messages_top_api_v1_community_path(community), params: { limit: 2 }
    expect(response.parsed_body["messages"].size).to eq(2)
  end

  it "returns messages ordered by engagement score descending" do
    low  = create(:message, community: community)
    high = create(:message, community: community)
    3.times { create(:reaction, message: high) }

    get messages_top_api_v1_community_path(community)
    ids = response.parsed_body["messages"].map { |m| m["id"] }
    expect(ids.first).to eq(high.id)
  end
end
