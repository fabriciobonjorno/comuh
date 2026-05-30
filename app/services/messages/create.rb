# frozen_string_literal: true

module Messages
  class Create
    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params.transform_keys(&:to_sym)
    end

    def call
      message = Message.create!(
        user: find_user,
        community_id: @params[:community_id],
        parent_message_id: @params[:parent_message_id],
        content: @params[:content],
        user_ip: @params[:user_ip],
        ai_sentiment_score: SentimentAnalyzer.call(@params[:content]).to_f
      )

      message
    end

    private

    def find_user
      if @params[:user_id].present?
        User.find(@params[:user_id])
      elsif @params[:username].present?
        User.find_or_create_by!(username: @params[:username])
      else
        raise ActiveRecord::RecordInvalid.new(Message.new.tap { |message| message.errors.add(:user, "must be provided via user_id or username") })
      end
    end
  end
end
