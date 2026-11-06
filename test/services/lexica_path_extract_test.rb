require "test_helper"
require "ostruct"

class LexicaPathExtractTest < ActiveSupport::TestCase
  def test_defaults_to_first_time_when_guest_omits_path_radio
    assert_equal "first_time", SeleniumServices::Lexica.extract_path([])
  end

  def test_defaults_to_first_time_when_only_non_path_rows_present
    rows = [OpenStruct.new(data_input_name: "payment_method", value: "gmo_atobarai")]
    assert_equal "first_time", SeleniumServices::Lexica.extract_path(rows)
  end

  def test_uses_explicit_path_value
    rows = [OpenStruct.new(data_input_name: "path", value: "existing")]
    assert_equal "existing", SeleniumServices::Lexica.extract_path(rows)
  end

  def test_raises_when_path_row_present_but_unknown
    rows = [OpenStruct.new(data_input_name: "path", value: "mystery")]
    error = assert_raises(ArgumentError) { SeleniumServices::Lexica.extract_path(rows) }
    assert_match(/unknown lexica path/, error.message)
  end
end
