# frozen_string_literal: true

class Reaction < ApplicationRecord
  TYPES = %w[like love insightful].freeze

  belongs_to :user
  belongs_to :message

  validates :user, :message, presence: true
  validates :reaction_type, presence: true, inclusion: { in: TYPES }
  validates :user_id, uniqueness: { scope: %i[message_id reaction_type] }

  after_create_commit :broadcast_reaction_counts

  private

  def broadcast_reaction_counts
    streams.each do |stream|
      broadcast_replace_to(
        *stream,
        target: ActionView::RecordIdentifier.dom_id(message, :reactions),
        partial: "messages/reactions",
        locals: { message: message }
      )
    end
  end

  def streams
    if message.parent_message.present?
      [ [ message.parent_message, :replies ] ]
    else
      [ [ message.community, :messages ], [ message, :thread ] ]
    end
  end
end
