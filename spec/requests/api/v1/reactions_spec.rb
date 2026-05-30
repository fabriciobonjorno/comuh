# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v1/reactions", type: :request do
  let(:message) { create(:message) }
  let(:user)    { create(:user) }

  let(:flat_payload) do
    {
      message_id: message.id,
      user_id: user.id,
      reaction_type: "like"
    }
  end

  let(:legacy_payload) do
    {
      reaction: {
        message_id: message.id,
        username: user.username,
        reaction_type: "like"
      }
    }
  end

  it "creates a reaction and returns 200 for flat payload" do
    post api_v1_reactions_path, params: flat_payload, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["message_id"]).to eq(message.id)
  end

  it "returns reaction counts in the response" do
    post api_v1_reactions_path, params: flat_payload, as: :json
    expect(response.parsed_body["reactions"]["like"]).to eq(1)
    expect(response.parsed_body["reactions"]["love"]).to eq(0)
    expect(response.parsed_body["reactions"]["insightful"]).to eq(0)
  end

  it "supports legacy nested reaction payload" do
    post api_v1_reactions_path, params: legacy_payload, as: :json
    expect(response).to have_http_status(:ok)
  end

  it "recreates the user when the provided user_id no longer exists but username is present" do
    message_id = message.id
    stale_user = create(:user, username: "alice")
    stale_id = stale_user.id
    stale_username = stale_user.username
    stale_user.destroy!

    expect {
      post api_v1_reactions_path, params: {
        message_id: message_id,
        user_id: stale_id,
        username: stale_username,
        reaction_type: "like"
      }, as: :json
    }.to change(User, :count).by(1).and change(Reaction, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["reactions"]["like"]).to eq(1)
  end

  context "when the user_id does not exist and no username is given" do
    it "returns 404 with code user_not_found" do
      post api_v1_reactions_path, params: {
        message_id: message.id,
        user_id: SecureRandom.uuid,
        reaction_type: "like"
      }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["code"]).to eq("user_not_found")
    end
  end

  context "when the reaction already exists" do
    before { create(:reaction, message: message, user: user, reaction_type: "like") }

    it "returns 409 conflict" do
      post api_v1_reactions_path, params: flat_payload, as: :json
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error"]).to eq("Reaction already exists")
    end

    it "does not create a duplicate reaction" do
      expect {
        post api_v1_reactions_path, params: flat_payload, as: :json
      }.not_to change(Reaction, :count)
    end
  end
end
