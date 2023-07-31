class AddSmsToPushMessages < ActiveRecord::Migration[7.0]
  def change
    add_reference :push_messages, :sms_template
  end
end
