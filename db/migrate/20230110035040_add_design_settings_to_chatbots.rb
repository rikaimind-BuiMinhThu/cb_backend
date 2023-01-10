class AddDesignSettingsToChatbots < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :design_settings, :text
  end
end
