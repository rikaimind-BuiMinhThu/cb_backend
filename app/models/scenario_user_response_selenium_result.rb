class ScenarioUserResponseSeleniumResult < ApplicationRecord
  enum result: { open: 0, running: 1, done: 2, error: 3 }

  PATH_LABELS = {
    "first_time" => "はじめて",
    "new" => "新規会員",
    "existing" => "既存会員"
  }.freeze

  PAYMENT_LABELS = {
    "credit" => "ZEUSクレジットカード",
    "zeus" => "ZEUSクレジットカード",
    "gmo_atobarai" => "GMO後払い",
    "cod" => "代金引換",
    "cash_on_delivery" => "代金引換"
  }.freeze

  def rpa_steps_array
    return [] if rpa_steps.blank?

    JSON.parse(rpa_steps)
  rescue JSON::ParserError
    []
  end

  def rpa_steps_array=(steps)
    self.rpa_steps = JSON.generate(Array(steps))
  end

  def append_rpa_step(step)
    steps = rpa_steps_array
    steps << step
    self.rpa_steps_array = steps
    save!
  end

  def path_label
    PATH_LABELS[path.to_s] || path
  end

  def payment_label
    PAYMENT_LABELS[payment.to_s] || payment
  end

  def token_failure?
    error_kind.to_s == "token_failure"
  end

  def submitted_to_cart?
    rpa_steps_array.any? { |step| step["name"].to_s == "submit_order" }
  end

  def retryable?
    error? && (token_failure? || !submitted_to_cart?)
  end
end
