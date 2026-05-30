# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "normalization" do
    it "strips whitespace and downcases username before validation" do
      user = build(:user, username: "  JohnDoe  ")
      user.valid?
      expect(user.username).to eq("johndoe")
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:username) }

    context "format" do
      it "accepts letters, numbers, underscores and hyphens" do
        expect(build(:user, username: "john_doe-99")).to be_valid
      end

      it "rejects spaces" do
        user = build(:user, username: "john doe")
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include(I18n.t("errors.messages.invalid_username"))
      end

      it "rejects special characters" do
        %w[john@ jo#hn jo.hn jo!hn].each do |bad|
          expect(build(:user, username: bad)).not_to be_valid
        end
      end

      it "rejects username starting with _ or -" do
        expect(build(:user, username: "_john")).not_to be_valid
        expect(build(:user, username: "-john")).not_to be_valid
      end
    end

    context "uniqueness" do
      it "enforces uniqueness of username among active records" do
        create(:user, username: "taken")
        duplicate = build(:user, username: "taken")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:username]).to be_present
      end

      it "allows reuse of a username after the original account is soft-deleted" do
        create(:user, :deleted, username: "reusable")
        expect(build(:user, username: "reusable")).to be_valid
      end

      it "is case-insensitive via normalization" do
        create(:user, username: "johndoe")
        expect(build(:user, username: "JohnDoe")).not_to be_valid
      end
    end
  end
end
