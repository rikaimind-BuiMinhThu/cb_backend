class ChangeEmailSubject < ActiveRecord::Migration[7.0]
  def change
    change_column :emails, :subject, :text
  end
end
