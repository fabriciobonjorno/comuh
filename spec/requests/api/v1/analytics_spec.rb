# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/v1/analytics/suspicious_ips", type: :request do
  it "returns 200" do
    get api_v1_analytics_suspicious_ips_path
    expect(response).to have_http_status(:ok)
  end

  it "returns a suspicious_ips array" do
    get api_v1_analytics_suspicious_ips_path
    expect(response.parsed_body["suspicious_ips"]).to be_an(Array)
  end

  it "includes IPs shared by multiple users" do
    community = create(:community)
    users = create_list(:user, 3)
    users.each { |u| create(:message, user: u, community: community, user_ip: "10.0.0.1") }

    get api_v1_analytics_suspicious_ips_path
    ips = response.parsed_body["suspicious_ips"].map { |r| r["ip"] }
    expect(ips).to include("10.0.0.1")
  end

  it "accepts a custom min_users param" do
    community = create(:community)
    users = create_list(:user, 2)
    users.each { |u| create(:message, user: u, community: community, user_ip: "10.0.0.2") }

    get api_v1_analytics_suspicious_ips_path, params: { min_users: 2 }
    ips = response.parsed_body["suspicious_ips"].map { |r| r["ip"] }
    expect(ips).to include("10.0.0.2")
  end
end
