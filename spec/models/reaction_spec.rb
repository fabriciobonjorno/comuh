# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reaction, type: :model do
  subject(:reaction) { build(:reaction) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:message) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:reaction_type) }
    it { is_expected.to validate_inclusion_of(:reaction_type).in_array(Reaction::TYPES) }

    it "rejects an unknown reaction_type" do
      expect(build(:reaction, reaction_type: "angry")).not_to be_valid
    end

    context "uniqueness" do
      it "prevents the same user reacting with the same type on the same message" do
        existing = create(:reaction)
        duplicate = build(:reaction, user: existing.user, message: existing.message, reaction_type: existing.reaction_type)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to be_present
      end

      it "allows the same user to react with a different type on the same message" do
        existing = create(:reaction, reaction_type: "like")
        other = build(:reaction, user: existing.user, message: existing.message, reaction_type: "love")
        expect(other).to be_valid
      end
    end
  end
end
