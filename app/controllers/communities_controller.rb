# frozen_string_literal: true

class CommunitiesController < ApplicationController
  def index
    @communities = CommunityListQuery.call
  end

  def show
    @community = Community.find(params[:id])
    @messages = CommunityMessagesQuery.call(@community)
  end
end
