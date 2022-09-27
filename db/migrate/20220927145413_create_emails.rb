class CreateEmails < ActiveRecord::Migration[7.0]
  def change
    create_table :emails do |t|
      t.string :email_template_name
      t.string :sender_name
      t.string :to
      t.string :reply_to
      t.string :subject
      t.string :content
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
