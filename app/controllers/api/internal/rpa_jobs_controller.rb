module Api
  module Internal
    class RpaJobsController < ApplicationController
      skip_before_action :permision

      def claim
        return render json: { action: "skip", reason: "unauthorized" }, status: :unauthorized unless token_ok?

        result = ScenarioUserResponseSeleniumResult.find_by(id: params[:id])
        return render json: { action: "skip", reason: "missing" } if result.blank?

        render json: Lexica::RpaClaim.call(result)
      end

      def events
        return head :unauthorized unless token_ok?

        result = ScenarioUserResponseSeleniumResult.find_by(id: params[:id])
        return head :not_found if result.blank?

        body = Lexica::RpaEvents.apply(result, params.to_unsafe_h)
        render json: body, status: body[:ok] ? :ok : :unprocessable_entity
      end

      private

      def token_ok?
        expected = ENV["LEXICA_RPA_CALLBACK_TOKEN"].to_s
        return false if expected.empty?

        provided = request.authorization.to_s.sub(/\ABearer /i, "")
        return false unless provided.bytesize == expected.bytesize

        ActiveSupport::SecurityUtils.secure_compare(provided, expected)
      end
    end
  end
end
