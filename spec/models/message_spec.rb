# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  subject(:message) { build(:message) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:community) }
    it { is_expected.to belong_to(:parent_message).class_name("Message").optional }
    it { is_expected.to have_many(:replies).class_name("Message").with_foreign_key(:parent_message_id).dependent(:destroy) }
    it { is_expected.to have_many(:reactions).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:user_ip) }

    context "ai_sentiment_score" do
      it "accepts nil" do
        expect(build(:message, ai_sentiment_score: nil)).to be_valid
      end

      it "accepts values between -1.0 and 1.0" do
        [ -1.0, 0.0, 0.5, 1.0 ].each do |score|
          expect(build(:message, ai_sentiment_score: score)).to be_valid
        end
      end

      it "rejects values outside -1.0..1.0" do
        [ -1.1, 1.1, 2.0 ].each do |score|
          msg = build(:message, ai_sentiment_score: score)
          expect(msg).not_to be_valid
          expect(msg.errors[:ai_sentiment_score]).to be_present
        end
      end
    end
  end

  describe "reply thread" do
    it "is valid as a top-level message without a parent" do
      expect(build(:message, parent_message: nil)).to be_valid
    end

    it "is valid as a reply with a parent" do
      expect(build(:message, :reply)).to be_valid
    end
  end
end
