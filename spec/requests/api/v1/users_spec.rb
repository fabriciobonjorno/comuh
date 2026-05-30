# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v1/users", type: :request do
  it "creates a user and returns 201" do
    post api_v1_users_path, params: { username: "alice" }, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["username"]).to eq("alice")
  end

  it "returns existing user for duplicate username" do
    user = create(:user, username: "alice")

    expect {
      post api_v1_users_path, params: { username: "alice" }, as: :json
    }.not_to change(User, :count)

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["id"]).to eq(user.id)
  end

  it "returns 422 for invalid username" do
    post api_v1_users_path, params: { username: "bad user" }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["error"]).to be_present
  end
end
