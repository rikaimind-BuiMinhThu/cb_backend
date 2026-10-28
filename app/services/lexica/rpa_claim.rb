module Lexica
  class RpaClaim
    MAX_ATTEMPTS = 3
    IN_FLIGHT_SECONDS = 300

    def self.call(result, client_cap: :lookup, in_flight_count: :lookup, now: Time.current)
      new(result, client_cap: client_cap, in_flight_count: in_flight_count, now: now).call
    end

    def initialize(result, client_cap:, in_flight_count:, now:)
      @result = result
      @client_cap = client_cap
      @in_flight_count = in_flight_count
      @now = now
    end

    def call
      if @result.respond_to?(:with_lock)
        @result.with_lock { decide }
      else
        decide
      end
    end

    private

    def decide
      return skip("done") if @result.done?
      return skip("submitted") if @result.order_submitted_at.present?
      return skip("not_retryable") if @result.error? && !@result.retryable?
      return skip("in_flight") if in_flight?

      unless crash_retry?
        cap_result = enforce_client_cap
        return cap_result if cap_result
        return skip("attempts_exhausted") if @result.rpa_attempt.to_i >= MAX_ATTEMPTS && @result.claimed_at.present?
      end

      start_run
    end

    def enforce_client_cap
      cap = resolved_cap
      return nil if cap.blank?
      return nil if resolved_in_flight < cap

      started = @result.defer_started_at
      if started.present? && @now - started >= SeleniumServices::ChromeSlot::WAIT_SECONDS
        @result.update!(
          result: :error,
          error_kind: "chrome_slot_timeout",
          error_message: "lexica chrome slot wait timed out",
          end_time: @now,
          last_step_description: "queued"
        )
        return skip("chrome_slot_timeout")
      end

      @result.update!(defer_started_at: started || @now)
      { action: "defer", retry_after: 30 }
    end

    def start_run
      attrs = {
        claimed_at: @now,
        last_step_description: "running",
        result: :running,
        defer_started_at: nil,
        end_time: nil,
        error_kind: nil,
        error_message: nil
      }
      attrs[:rpa_attempt] = @result.rpa_attempt.to_i + 1 unless crash_retry?
      @result.update!(attrs)
      { action: "run", job: Lexica::JobPayload.build(@result) }
    end

    def in_flight?
      @result.running? && @result.claimed_at.present? && @result.end_time.nil? && age < IN_FLIGHT_SECONDS
    end

    def crash_retry?
      @result.running? && @result.claimed_at.present? && @result.end_time.nil? && age >= IN_FLIGHT_SECONDS
    end

    def age
      @now - @result.claimed_at
    end

    def resolved_cap
      return nil if @client_cap.nil?
      return @client_cap unless @client_cap == :lookup

      client = Client.find_by(id: @result.client_id)
      raw = client&.lexica_max_chrome
      return nil if raw.blank?

      SystemSetting.clamp_chrome(raw)
    end

    def resolved_in_flight
      return @in_flight_count unless @in_flight_count == :lookup

      ScenarioUserResponseSeleniumResult
        .where(client_id: @result.client_id, result: ScenarioUserResponseSeleniumResult.results[:running])
        .where.not(claimed_at: nil)
        .where(end_time: nil)
        .where.not(id: @result.id)
        .count
    end

    def skip(reason)
      { action: "skip", reason: reason }
    end
  end
end
