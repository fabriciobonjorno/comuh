# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Messages and reactions", type: :system do
  let(:community) { create(:community) }

  it "creates a message without reload and renders sentiment and reaction controls" do
    visit community_path(community)

    fill_in "message_username", with: "new_user"
    fill_in "message_content", with: "I love this community"
    click_button "Post message"

    expect(page).to have_field("message_username", with: "new_user")

    within find("#messages article", wait: 10) do
      expect(page).to have_css('[data-controller="reaction"]')
      expect(page).to have_css('[data-reaction-target="likeCount"]')
      expect(page).to have_css('[data-reaction-target="loveCount"]')
      expect(page).to have_css('[data-reaction-target="insightfulCount"]')
      expect(page).to have_css('span.inline-flex', text: /(Positive|Neutral|Negative)/)
      expect(page).to have_link("View thread →")
    end
  end

  it "updates reaction counts without reload and shows duplicate reaction feedback" do
    visit community_path(community)

    fill_in "message_username", with: "reactor"
    fill_in "message_content", with: "A new message to react to"
    click_button "Post message"

    within find("#messages article", wait: 10) do
      within find('[data-controller="reaction"]') do
        find("button", text: /👍/).click
        expect(page).to have_text("1")

        find("button", text: /👍/).click
        expect(page).to have_text("Reaction already exists")
        expect(page).to have_text("1")
      end
    end
  end

  it "shows the communities index page with cards and message counts" do
    create(:message, community: community)

    visit root_path

    expect(page).to have_text(community.name)
    expect(page).to have_text(community.description)
    expect(page).to have_text("1 msgs")
    expect(page).to have_link(community.name, href: community_path(community))
  end

  it "renders a message thread page with original message and replies" do
    parent_message = create(:message, community: community, content: "Parent message", user: create(:user, username: "author"))
    create(:message, community: community, parent_message_id: parent_message.id, content: "Reply message", user: create(:user, username: "replier"))

    visit message_path(parent_message)

    expect(page).to have_text("Parent message")
    expect(page).to have_text("Reply message")
    expect(page).to have_field("message_username")
    expect(page).to have_button("Reply")
  end
end
