# frozen_string_literal: true

module Api
  module V1
    class AnalyticsController < BaseController
      def suspicious_ips
        result = SuspiciousIpsQuery.call(
          min_users: params.fetch(:min_users, 3).to_i
        )

        render json: { suspicious_ips: result }
      end
    end
  end
end
