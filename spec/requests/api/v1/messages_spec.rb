# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v1/messages", type: :request do
  let(:community) { create(:community) }
  let(:user) { create(:user) }

  let(:flat_payload) do
    {
      content: "Hello world",
      user_id: user.id,
      community_id: community.id,
      user_ip: "127.0.0.1"
    }
  end

  let(:nested_payload) do
    {
      message: {
        username: "tester",
        community_id: community.id,
        content: "Hello world",
        user_ip: "127.0.0.1"
      }
    }
  end

  it "creates a message and returns 201 for flat payload" do
    post api_v1_messages_path, params: flat_payload, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["content"]).to eq("Hello world")
    expect(response.parsed_body.dig("user", "id")).to eq(user.id)
    expect(response.parsed_body["ai_sentiment_score"]).to be_between(-1.0, 1.0)

    message = Message.find(response.parsed_body["id"])
    expect(message.ai_sentiment_score).to eq(response.parsed_body["ai_sentiment_score"])
  end

  it "returns ai_sentiment_score in the JSON response" do
    payload = flat_payload.merge(content: "I love this community")

    post api_v1_messages_path, params: payload, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["ai_sentiment_score"]).to be > 0
    expect(response.parsed_body["html"]).to include("😊")
    expect(response.parsed_body["html"]).to include("bg-green-100")
  end

  it "supports legacy nested message payload" do
    post api_v1_messages_path, params: nested_payload, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig("user", "username")).to eq("tester")
  end

  it "returns rendered HTML for the created message" do
    post api_v1_messages_path, params: flat_payload, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["html"]).to include('data-controller="reaction"')
    expect(response.parsed_body["html"]).to include("View thread →")
  end

  it "renders replies without a thread link when parent_message_id is present" do
    parent_message = create(:message, community: community)
    reply_payload = flat_payload.merge(parent_message_id: parent_message.id)

    post api_v1_messages_path, params: reply_payload, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["html"]).not_to include("View thread →")
  end

  it "creates the user if it does not exist with legacy payload" do
    expect { post api_v1_messages_path, params: nested_payload, as: :json }
      .to change(User, :count).by(1)
  end

  it "returns 422 when content is blank" do
    invalid_payload = flat_payload.merge(content: "")

    post api_v1_messages_path, params: invalid_payload, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["error"]).to be_present
  end
end
