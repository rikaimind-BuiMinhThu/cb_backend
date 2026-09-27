class AddChatBodyVersionToChatbots < ActiveRecord::Migration[7.0]
  def change
    # Existing production LPs must stay on the v1 body. Default 1.0 so a first-run
    # migrate does not backfill every row to 2.0 (that would switch sdk-v2.js
    # customers to /v2/sdk.js if the version gate is ever placed on production root).
    add_column :chatbots, :chat_body_version, :string, null: false, default: "1.0"
  end
end
