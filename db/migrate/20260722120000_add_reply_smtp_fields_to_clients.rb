class AddReplySmtpFieldsToClients < ActiveRecord::Migration[7.0]
  def change
    add_column :clients, :reply_smtp_gmail, :string
    add_column :clients, :reply_smtp_gmail_app_password, :string
  end
end
