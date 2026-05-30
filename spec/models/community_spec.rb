# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Community, type: :model do
  subject(:community) { build(:community) }

  describe "associations" do
    it { is_expected.to have_many(:messages).dependent(:destroy) }
  end

  describe "normalization" do
    it "strips leading and trailing whitespace from name before validation" do
      community = build(:community, name: "  Open Source  ")
      community.valid?
      expect(community.name).to eq("Open Source")
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    context "uniqueness" do
      it "enforces uniqueness of name among active records" do
        create(:community, name: "taken")
        duplicate = build(:community, name: "taken")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to be_present
      end

      it "allows reuse of a name after the original community is soft-deleted" do
        create(:community, :deleted, name: "reusable")
        expect(build(:community, name: "reusable")).to be_valid
      end
    end
  end
end
