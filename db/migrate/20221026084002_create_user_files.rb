class CreateUserFiles < ActiveRecord::Migration[7.0]
  def change
    create_table :user_files do |t|
      t.string :file_url
      t.string :file_type
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
