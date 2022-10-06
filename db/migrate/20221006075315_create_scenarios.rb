class CreateScenarios < ActiveRecord::Migration[7.0]
  def change
    create_table :scenarios do |t|
      t.string :name
      t.references :chatbot, null: false, foreign_key: true

      t.timestamps
    end
  end
end
