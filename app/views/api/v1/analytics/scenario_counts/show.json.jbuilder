json.code 1
json.data do
  json.extract! @scenario, :id
  if @analytic_scenarios.present?
    json.pc_count @analytic_scenarios.pc.length
    json.tablet_count @analytic_scenarios.tablet.length
    json.smartphone_count @analytic_scenarios.smartphone.length
    json.pc_conversion_count @analytic_scenarios.pc_conversion.length
    json.tablet_conversion_count @analytic_scenarios.tablet_conversion.length
    json.smartphone_conversion_count @analytic_scenarios.smartphone_conversion.length
    json.pc_open_chatbot_window_count @analytic_scenarios.pc_open_chatbot_window.length
    json.tablet_open_chatbot_window_count @analytic_scenarios.tablet_open_chatbot_window.length
    json.smartphone_open_chatbot_window_count @analytic_scenarios.smartphone_open_chatbot_window.length
    json.pc_close_chatbot_window_count @analytic_scenarios.pc_close_chatbot_window.length
    json.tablet_close_chatbot_window_count @analytic_scenarios.tablet_close_chatbot_window.length
    json.smartphone_close_chatbot_window_count @analytic_scenarios.smartphone_close_chatbot_window.length
  end
end
