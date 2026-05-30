# frozen_string_literal: true

require "rails_helper"

RSpec.describe MessageSerializer do
  let(:message) { create(:message) }

  subject(:json) { described_class.new(message).as_json }

  it "includes id" do
    expect(json[:id]).to eq(message.id)
  end

  it "includes content" do
    expect(json[:content]).to eq(message.content)
  end

  it "includes user with id and username" do
    expect(json[:user]).to eq({ id: message.user.id, username: message.user.username })
  end

  it "includes community_id" do
    expect(json[:community_id]).to eq(message.community_id)
  end

  it "includes parent_message_id" do
    expect(json[:parent_message_id]).to eq(message.parent_message_id)
  end

  it "includes ai_sentiment_score" do
    expect(json).to have_key(:ai_sentiment_score)
  end

  it "includes created_at" do
    expect(json[:created_at]).to eq(message.created_at)
  end
end
