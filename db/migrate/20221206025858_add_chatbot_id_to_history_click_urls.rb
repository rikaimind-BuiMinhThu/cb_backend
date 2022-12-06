class AddChatbotIdToHistoryClickUrls < ActiveRecord::Migration[7.0]
  def change
    add_reference :history_click_urls, :chatbot, null: false, foreign_key: true
  end
end
