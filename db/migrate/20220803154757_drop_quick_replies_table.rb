class DropQuickRepliesTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :quick_replies
  end
end
