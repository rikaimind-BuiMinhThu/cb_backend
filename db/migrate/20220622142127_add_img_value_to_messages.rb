class AddImgValueToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :img_value, :string
  end
end
