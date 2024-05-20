class AddColumnMainColorOtherToChatbot < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :main_color_other, :string
  end
end
