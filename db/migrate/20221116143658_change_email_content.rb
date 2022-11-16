class ChangeEmailContent < ActiveRecord::Migration[7.0]
  def change
    change_column :emails, :content, :text
  end
end
