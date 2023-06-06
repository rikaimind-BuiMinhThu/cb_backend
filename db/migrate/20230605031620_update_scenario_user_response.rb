class UpdateScenarioUserResponse < ActiveRecord::Migration[7.0]
  def up
    ScenarioUserResponse.where(data_input_name: ["user_email","user_name","user_name_kana","first_name_kana","last_name_kana","phone_number","password","quantity","last_name","first_name","coupons_code","pin_code"]).update_all(ui_type: 'text_input')
    ScenarioUserResponse.where(data_input_name: ["zip_code_address"]).update_all(ui_type: 'zip_code_address')
    ScenarioUserResponse.where(data_input_name: ["is_regular_order","has_account","delivery_frequency","delivery_method","payment_method","sex"]).update_all(ui_type: 'radio_button')
    ScenarioUserResponse.where(data_input_name: ["credit_card_payment","paypal_payment","komoju_payment","paidy_payment","np_delivery_payment"]).update_all(ui_type: 'card_payment_radio_button')
    ScenarioUserResponse.where(data_input_name: ["birth_date","delivery_date","delivery_time","quantity","delivery_method","country"]).update_all(ui_type: 'pull_down')
    ScenarioUserResponse.where(data_input_name: ["sent_message"]).update_all(ui_type: 'textarea')
  end

  def down
    ScenarioUserResponse.update_all(ui_type: nil)
  end
end
