# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Messages", type: :request do
  describe "GET /messages/:id" do
    it "returns http success" do
      message = create(:message)
      get message_path(message)
      expect(response).to have_http_status(:success)
    end
  end
end
