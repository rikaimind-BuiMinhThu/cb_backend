# frozen_string_literal: true

class ChangeScenariosConversationToMediumtext < ActiveRecord::Migration[7.0]
  def up
    change_column :scenarios, :conversation, :longtext
  end

  def down
    change_column :scenarios, :conversation, :text
  end
end
