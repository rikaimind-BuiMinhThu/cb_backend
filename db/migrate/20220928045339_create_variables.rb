class CreateVariables < ActiveRecord::Migration[7.0]
  def change
    create_table :variables do |t|
      t.string :variable_name
      t.string :default_value
      t.references :chatbot, null: false, foreign_key: true

      t.timestamps
    end
  end
end
