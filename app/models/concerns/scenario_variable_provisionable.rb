module ScenarioVariableProvisionable
  extend ActiveSupport::Concern

  VARIABLE_PLACEHOLDER_REGEX = /\{\{\s*([^}\s]+)\s*\}\}/

  def provision_variables_for!(scenario)
    chatbot = scenario.chatbot
    return if chatbot.blank?

    extract_variable_names.each do |name|
      next if Variable::DEFAULT_VARIABLES.include?(name)

      Variable.find_or_create_by!(chatbot: chatbot, variable_name: name) do |variable|
        variable.default_value = ""
      end
    end
  end

  def extract_variable_names
    names = []
    collect_variable_names(parsed_conversation, names)
    names.map { |name| name.to_s.strip }.reject(&:blank?).uniq
  end

  private

  def parsed_conversation
    raw = conversation
    return {} if raw.blank?
    return raw if raw.is_a?(Hash) || raw.is_a?(Array)

    JSON.parse(raw)
  rescue JSON::ParserError
    {}
  end

  def collect_variable_names(node, names)
    case node
    when Hash
      collect_from_hash(node, names)
      node.each_value { |value| collect_variable_names(value, names) }
    when Array
      node.each { |value| collect_variable_names(value, names) }
    when String
      node.scan(VARIABLE_PLACEHOLDER_REGEX) { |match| names << match[0] }
    end
  end

  def collect_from_hash(node, names)
    save_name = node["save_input_content"] || node[:save_input_content]
    names << save_name if save_name.is_a?(String)

    variable_set = node["variable_set"] || node[:variable_set]
    if variable_set.is_a?(Hash)
      (variable_set["variables"] || variable_set[:variables] || []).each do |item|
        names << (item["key"] || item[:key]) if item.is_a?(Hash)
      end
    end

    clear_variable = node["clear_variable"] || node[:clear_variable]
    return unless clear_variable.is_a?(Hash)

    (clear_variable["variables"] || clear_variable[:variables] || []).each do |item|
      names << item if item.is_a?(String)
      names << (item["key"] || item[:key]) if item.is_a?(Hash)
    end
  end
end
