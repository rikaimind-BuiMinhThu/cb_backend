class AddPreviewPastPostUrlToMesssages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :preview_past_post_url, :text
  end
end
