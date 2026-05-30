# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Communities", type: :request do
  describe "GET /communities" do
    it "returns http success" do
      get communities_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /communities/:id" do
    it "returns http success" do
      community = create(:community)
      get community_path(community)
      expect(response).to have_http_status(:success)
    end
  end
end
