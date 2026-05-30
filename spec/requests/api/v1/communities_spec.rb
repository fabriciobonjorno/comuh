# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v1/communities", type: :request do
  it "creates a community and returns 201" do
    post api_v1_communities_path, params: { name: "new-community", description: "A test community." }, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["name"]).to eq("new-community")
    expect(response.parsed_body["description"]).to eq("A test community.")
  end

  it "returns 422 for missing name" do
    post api_v1_communities_path, params: { description: "No name" }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["error"]).to be_present
  end
end
