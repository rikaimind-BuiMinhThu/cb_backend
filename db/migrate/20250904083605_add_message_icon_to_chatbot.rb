class AddMessageIconToChatbot < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :message_icon, :text, defalt: "", null: true
    remove_columns :chatbots, :avatar_pc, :avatar_mobile, :avatar_on_open, type: :string
  end
end