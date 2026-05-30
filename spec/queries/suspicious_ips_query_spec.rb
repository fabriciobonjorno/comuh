# frozen_string_literal: true

require "rails_helper"

RSpec.describe SuspiciousIpsQuery do
  let(:community) { create(:community) }

  describe ".call" do
    it "returns an array" do
      expect(described_class.call).to be_an(Array)
    end

    it "flags IPs shared by min_users or more distinct users" do
      users = create_list(:user, 3)
      users.each { |u| create(:message, user: u, community: community, user_ip: "1.2.3.4") }

      result = described_class.call(min_users: 3)
      expect(result.map { |r| r[:ip] }).to include("1.2.3.4")
    end

    it "excludes IPs below the min_users threshold" do
      users = create_list(:user, 2)
      users.each { |u| create(:message, user: u, community: community, user_ip: "9.9.9.9") }

      result = described_class.call(min_users: 3)
      expect(result.map { |r| r[:ip] }).not_to include("9.9.9.9")
    end

    it "returns user_count and usernames for each suspicious IP" do
      users = create_list(:user, 3)
      users.each { |u| create(:message, user: u, community: community, user_ip: "5.5.5.5") }

      entry = described_class.call(min_users: 3).find { |r| r[:ip] == "5.5.5.5" }
      expect(entry[:user_count]).to eq(3)
      expect(entry[:usernames]).to match_array(users.map(&:username))
    end

    it "uses min_users default of 3" do
      users = create_list(:user, 3)
      users.each { |u| create(:message, user: u, community: community, user_ip: "3.3.3.3") }

      expect(described_class.call.map { |r| r[:ip] }).to include("3.3.3.3")
    end
  end
end
