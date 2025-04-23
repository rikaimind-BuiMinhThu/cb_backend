class AddErrMsgByJsOptionToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :is_used_err_msg_by_js, :boolean, default: false
    add_column :scenarios, :err_msg_js_code, :text
  end
end
