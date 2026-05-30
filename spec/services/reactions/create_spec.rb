# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reactions::Create do
  let(:message) { create(:message) }
  let(:user)    { create(:user) }
  let(:params)  { { message_id: message.id, user_id: user.id, reaction_type: "like" } }

  describe ".call" do
    it "creates the reaction" do
      expect { described_class.call(params) }.to change(Reaction, :count).by(1)
    end

    it "returns reaction counts keyed by type" do
      counts = described_class.call(params)
      expect(counts["like"]).to eq(1)
    end

    it "counts all reaction types for the message" do
      other_user = create(:user)
      create(:reaction, message: message, user: other_user, reaction_type: "love")
      counts = described_class.call(params)
      expect(counts["like"]).to eq(1)
      expect(counts["love"]).to eq(1)
    end

    context "when the same reaction already exists" do
      before { create(:reaction, message: message, user: user, reaction_type: "like") }

      it "raises DuplicateReactionError" do
        expect { described_class.call(params) }.to raise_error(DuplicateReactionError)
      end

      it "does not create a duplicate reaction" do
        expect { described_class.call(params) rescue nil }.not_to change(Reaction, :count)
      end
    end

    it "raises DuplicateReactionError for concurrent duplicate requests" do
      errors = []
      threads = 2.times.map do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            begin
              described_class.call(params)
            rescue StandardError => e
              errors << e
            end
          end
        end
      end

      threads.each(&:join)

      expect(Reaction.where(message: message, user: user, reaction_type: "like").count).to eq(1)
      expect(errors.any? { |error| error.is_a?(DuplicateReactionError) }).to be true
    end
  end
end
