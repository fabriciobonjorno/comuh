# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommunityCardComponent, type: :component do
  it "renders the community card with name, description and message count" do
    community = build_stubbed(:community, name: "Test community", description: "A sample community")
    community.define_singleton_method(:messages_count) { 3 }

    render_inline(described_class.new(community: community))

    expect(page).to have_text("Test community")
    expect(page).to have_text("A sample community")
    expect(page).to have_text("3 msgs")
  end
end
