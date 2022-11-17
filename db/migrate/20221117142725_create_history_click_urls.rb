class CreateHistoryClickUrls < ActiveRecord::Migration[7.0]
  def change
    create_table :history_click_urls do |t|
      t.integer :num_of_click
      t.string :origin_url
      t.string :shorten_code
      t.references :chatbot, null: false, foreign_key: true

      t.timestamps
    end
    add_index :history_click_urls, :shorten_code
  end
end
