require "test_helper"

class FilterParameterLoggingTest < ActiveSupport::TestCase
  test "masks nested card_number and cvc in scenario response-shaped payload" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    payload = {
      "scenario_user_response" => {
        "card_number" => "4111111111111111",
        "cvc" => "123",
        "cvv" => "456",
        "security_code" => "789",
        "email" => "user@example.com"
      }
    }

    filtered = filter.filter(payload)
    nested = filtered.fetch("scenario_user_response")

    assert_equal "[FILTERED]", nested["card_number"]
    assert_equal "[FILTERED]", nested["cvc"]
    assert_equal "[FILTERED]", nested["cvv"]
    assert_equal "[FILTERED]", nested["security_code"]
    assert_equal "user@example.com", nested["email"]
  end
end
