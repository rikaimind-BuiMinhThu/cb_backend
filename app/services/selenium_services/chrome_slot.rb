module SeleniumServices
  class ChromeSlot
    GLOBAL_KEY = "lexica_chrome"
    WAIT_SECONDS = 600
    POLL_SECONDS = 1

    def initialize(client)
      @client = client
    end

    def with_slot
      acquired_global = false
      acquired_client = false
      begin
        wait_for { try_acquire(GLOBAL_KEY, global_max) }
        acquired_global = true
        wait_for { try_acquire(client_key, effective_max) }
        acquired_client = true
        yield
      ensure
        release(client_key) if acquired_client
        release(GLOBAL_KEY) if acquired_global
      end
    end

    def queued?
      global_count >= global_max || client_count >= effective_max
    end

    def global_max
      SystemSetting.lexica_max_chrome
    end

    def effective_max
      client_cap = @client&.lexica_max_chrome
      return global_max if client_cap.blank?

      [SystemSetting.clamp_chrome(client_cap), global_max].min
    end

    private

    def client_key
      "#{GLOBAL_KEY}:#{@client.id}"
    end

    def global_count
      redis_get(GLOBAL_KEY)
    end

    def client_count
      redis_get(client_key)
    end

    def wait_for
      deadline = Time.now + WAIT_SECONDS
      loop do
        return true if yield
        raise Timeout::Error, "lexica chrome slot wait timed out" if Time.now >= deadline

        sleep POLL_SECONDS
      end
    end

    def try_acquire(key, max)
      script = <<~LUA
        local n = redis.call('incr', KEYS[1])
        redis.call('expire', KEYS[1], ARGV[2])
        if n > tonumber(ARGV[1]) then
          redis.call('decr', KEYS[1])
          return 0
        end
        return 1
      LUA
      redis { |r| r.eval(script, keys: [key], argv: [max, WAIT_SECONDS + 60]) }.to_i == 1
    end

    def release(key)
      script = <<~LUA
        local n = tonumber(redis.call('get', KEYS[1]) or '0')
        if n <= 0 then
          redis.call('del', KEYS[1])
          return 0
        end
        return redis.call('decr', KEYS[1])
      LUA
      redis { |r| r.eval(script, keys: [key]) }
    rescue StandardError => e
      Rails.logger.error("ChromeSlot release failed: #{e.message}")
    end

    def redis_get(key)
      redis { |r| r.get(key).to_i }
    end

    def redis
      Sidekiq.redis { |r| yield r }
    end
  end
end
