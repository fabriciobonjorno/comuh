# frozen_string_literal: true

Rails.application.config.after_initialize do
  next unless defined?(SolidCable::Message)

  module SolidCableBroadcastInsertBang
    def broadcast(channel, payload)
      insert!(
        {
          created_at: Time.current,
          channel: channel,
          payload: payload,
          channel_hash: channel_hash_for(channel)
        },
        returning: false
      )
    end
  end

  SolidCable::Message.singleton_class.prepend(SolidCableBroadcastInsertBang)
end
