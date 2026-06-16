class AddErrMsgAndLaunchButtonSettingsToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :err_msg_setting_mode, :string, default: 'js'
    add_column :scenarios, :err_msg_field_selectors, :text
    add_column :scenarios, :err_msg_form_selectors, :text
    add_column :scenarios, :launch_button_selectors, :text
  end
end
