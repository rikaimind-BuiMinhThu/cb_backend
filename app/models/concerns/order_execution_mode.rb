module OrderExecutionMode
  MODES = {
    undecided: 0,
    fukushashiki_only: 1,
    api_only: 2,
    rpa: 3
  }.freeze

  module_function

  def resolve(client, _scenario = nil)
    client_mode = normalize(client&.order_execution_mode)
    return client_mode if client_mode.present? && client_mode != :undecided

    :rpa
  end

  def normalize(value)
    return nil if value.blank?

    key = value.to_s.to_sym
    return key if MODES.key?(key)

    numeric = value.to_i
    MODES.key(numeric)
  end
end
