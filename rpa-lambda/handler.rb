require "json"
require "net/http"
require "uri"
require_relative "boot"
require_relative "app/services/lexica/rpa_queue"
require_relative "app/services/lexica/rpa_dispatch"
require_relative "app/services/selenium_services/base"
require_relative "app/services/selenium_services/lexica"
require_relative "app/services/selenium_services/lexica/selectors"
require_relative "app/services/selenium_services/lexica/offer_resolver"
require_relative "app/services/selenium_services/lexica/base"
require_relative "app/services/selenium_services/lexica/checkout"
require_relative "app/services/selenium_services/lexica/first_time"
require_relative "app/services/selenium_services/lexica/new_member"
require_relative "app/services/selenium_services/lexica/existing"
require_relative "app/services/selenium_services/lexica/job_context"
require_relative "app/services/selenium_services/lexica/http_result_sink"

class Handler
  def self.process(event:, context:)
    new(event).call
  end

  def initialize(event)
    @event = event || {}
  end

  def call
    Log.debug_mode(:stdout)
    failures = []
    records.each do |record|
      handle_record(record)
    rescue StandardError => error
      warn "lexica rpa record failed: #{error.class}: #{error.message}"
      warn_chromedriver_failure
      failures << { "itemIdentifier" => record["messageId"] }
    end
    { "batchItemFailures" => failures }
  end

  private

  def records
    Array(@event["Records"])
  end

  def warn_chromedriver_failure
    ["/tmp/chromedriver.log", "/tmp/chrome.log"].each do |path|
      next unless File.file?(path)

      lines = File.readlines(path, chomp: true).last(30).filter_map { |line|
        snippet = line[0, 180]
        next if snippet.match?(/\d{13,}/)

        snippet
      }
      warn "#{path}:\n#{lines.join("\n")}" unless lines.empty?
    end
  rescue StandardError
    nil
  end

  def handle_record(record)
    body = JSON.parse(record.fetch("body"))
    result_id = body.fetch("selenium_result_id")
    claim = claim_job(result_id)
    case Lexica::RpaDispatch.action_for(claim)
    when :requeue
      Lexica::RpaQueue.enqueue(result_id, delay_seconds: claim.fetch("retry_after", 30).to_i)
    when :run
      run_job(claim.fetch("job"))
    else
      nil
    end
  end

  def claim_job(result_id)
    uri = URI("#{callback_base}/api/internal/rpa/jobs/#{result_id}/claim")
    response = post_json(uri, {})
    JSON.parse(response)
  end

  def run_job(job)
    scenario, conversations = SeleniumServices::Lexica::JobContext.from_job(job)
    sink = SeleniumServices::Lexica::HttpResultSink.new(
      base_url: callback_base,
      token: callback_token,
      result_id: job.fetch("result_id"),
      client_id: job.fetch("client_id")
    )
    service = SeleniumServices::Lexica.build(scenario, conversations, sink: sink)
    service.process
  end

  def post_json(uri, payload)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{callback_token}"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(payload)
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.open_timeout = 10
      http.read_timeout = 30
      http.request(request)
    end
    raise "claim failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    response.body
  end

  def callback_base
    ENV.fetch("LEXICA_RPA_CALLBACK_BASE_URL").sub(%r{/+\z}, "")
  end

  def callback_token
    ENV.fetch("LEXICA_RPA_CALLBACK_TOKEN")
  end
end
