class CreateClientEmails < ActiveRecord::Migration[7.0]
  def change
    create_table :client_emails do |t|
      t.string :email
      t.string :password
      t.references :client, foreign_key: true

      t.timestamps
    end
  end
end
