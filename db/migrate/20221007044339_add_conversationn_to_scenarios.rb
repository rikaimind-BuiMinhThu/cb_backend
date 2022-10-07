class AddConversationnToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :conversation, :text
  end
end
