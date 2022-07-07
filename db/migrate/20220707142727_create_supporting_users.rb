class CreateSupportingUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :supporting_users do |t|
      t.string :sender_id
      t.references :instagram_account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
