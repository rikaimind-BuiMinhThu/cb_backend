class UpdateInstagramUserLabels < ActiveRecord::Migration[7.0]
  def change
    remove_column :instagram_user_labels, :message_button_label_id
    add_column :instagram_user_labels, :name, :string
  end
end
