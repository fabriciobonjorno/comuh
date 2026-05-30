# frozen_string_literal: true

require "rails_helper"

RSpec.describe Messages::Create do
  subject(:result) { described_class.call(params) }

  let(:community) { create(:community) }
  let(:user) { create(:user) }
  let(:base_params) do
    { username: "tester", community_id: community.id, content: "Hello world", user_ip: "127.0.0.1" }
  end

  describe ".call" do
    context "when user does not exist" do
      let(:params) { base_params }

      it "creates the user" do
        expect { result }.to change(User, :count).by(1)
      end

      it "creates the message" do
        expect { result }.to change(Message, :count).by(1)
      end

      it "returns the created message" do
        expect(result).to be_a(Message)
        expect(result).to be_persisted
      end
    end

    context "when user_id is provided" do
      let!(:user) { create(:user) }
      let(:params) { { user_id: user.id, community_id: community.id, content: "Hello world", user_ip: "127.0.0.1" } }

      it "uses the existing user without creating a new record" do
        expect { result }.not_to change(User, :count)
      end

      it "assigns the existing user to the created message" do
        expect(result.user).to eq(user)
      end
    end

    context "when user already exists by username" do
      let!(:user) { create(:user, username: "tester") }
      let(:params) { base_params }

      it "reuses the existing user" do
        expect { result }.not_to change(User, :count)
      end

      it "assigns the existing user to the message" do
        expect(result.user).to eq(user)
      end
    end

    it "calculates ai_sentiment_score from content" do
      params = base_params.merge(content: "ótimo trabalho")
      message = described_class.call(params)
      expect(message.ai_sentiment_score).not_to be_nil
    end

    it "sets parent_message_id when parent_message_id is given" do
      parent_message = create(:message, community: community)
      params = base_params.merge(parent_message_id: parent_message.id)
      expect(described_class.call(params).parent_message_id).to eq(parent_message.id)
    end

    it "raises ActiveRecord::RecordInvalid when content is blank" do
      params = base_params.merge(content: "")
      expect { described_class.call(params) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
