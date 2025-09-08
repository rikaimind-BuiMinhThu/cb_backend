class UseFullwidthChatbotMobile < ActiveRecord::Migration[7.0]
  def change
    add_column :scenarios, :use_fullwidth_chatbot_mobile, :boolean, default: false
  end
end
