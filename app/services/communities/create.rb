# frozen_string_literal: true

module Communities
  class Create
    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params.transform_keys(&:to_sym)
    end

    def call
      Community.create!(name: @params[:name], description: @params[:description])
    end
  end
end
