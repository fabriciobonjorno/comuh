# frozen_string_literal: true

module Users
  class Create
    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params.transform_keys(&:to_sym)
    end

    def call
      User.find_or_create_by!(username: @params[:username])
    end
  end
end
