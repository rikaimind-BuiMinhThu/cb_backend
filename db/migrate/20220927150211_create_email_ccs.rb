class CreateEmailCcs < ActiveRecord::Migration[7.0]
  def change
    create_table :email_ccs do |t|
      t.references :email, null: false, foreign_key: true
      t.string :to

      t.timestamps
    end
  end
end
