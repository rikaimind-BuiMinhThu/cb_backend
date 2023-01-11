class AddDesignSettingsToChatbots < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :design_settings, :text, :limit => 4294967295
  end
end
