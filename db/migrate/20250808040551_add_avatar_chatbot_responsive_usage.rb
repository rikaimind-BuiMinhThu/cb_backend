class AddAvatarChatbotResponsiveUsage < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :avatar_pc, :string, :limit => 255, default: ""
    add_column :chatbots, :avatar_mobile, :string, :limit => 255, default: ""
    add_column :chatbots, :avatar_on_open, :string, :limit => 255, default: ""
  end
end
