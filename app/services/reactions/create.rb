# frozen_string_literal: true

module Reactions
  class Create
    def self.call(params) = new(params).call

    def initialize(params)
      @params = params.transform_keys(&:to_sym)
    end

    def call
      message = find_message
      user = find_user

      raise DuplicateReactionError if Reaction.exists?(message_id: message.id, user_id: user.id, reaction_type: @params[:reaction_type])

      Reaction.create!(message: message, user: user, reaction_type: @params[:reaction_type])
      message.reaction_counts
    rescue ActiveRecord::RecordNotUnique
      raise DuplicateReactionError
    rescue ActiveRecord::RecordInvalid => e
      raise DuplicateReactionError if duplicate_reaction_error?(e)
      raise
    end

    private

    def find_message
      Message.find(@params[:message_id])
    end

    def find_user
      if @params[:user_id].present?
        find_user_by_id
      elsif @params[:username].present?
        User.find_or_create_by!(username: @params[:username])
      else
        raise ActiveRecord::RecordInvalid.new(Reaction.new.tap { |reaction| reaction.errors.add(:user, "must be provided via user_id or username") })
      end
    end

    def find_user_by_id
      User.find(@params[:user_id])
    rescue ActiveRecord::RecordNotFound
      return User.find_or_create_by!(username: @params[:username]) if @params[:username].present?

      raise
    end

    def duplicate_reaction_error?(exception)
      exception.record.errors.added?(:user_id, :taken) || exception.record.errors.added?(:user, :taken)
    end

    def reaction_counts
      Reaction.where(message_id: @params[:message_id]).group(:reaction_type).count
    end
  end
end
