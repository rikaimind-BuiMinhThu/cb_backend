class ChangeChatBodyVersionDefaultTo10 < ActiveRecord::Migration[7.0]
  def up
    return unless column_exists?(:chatbots, :chat_body_version)

    change_column_default :chatbots, :chat_body_version, "1.0"

    # Staging already opted bots into 2.0 for v2 QA. Only rewrite existing rows
    # when an operator explicitly opts production in:
    #   ECCH_PRODUCTION_BODY_VERSION_BACKFILL=1 bin/rails db:migrate
    # or: bin/rails chatbots:backfill_body_version_1 CONFIRM=yes
    if ENV["ECCH_PRODUCTION_BODY_VERSION_BACKFILL"] == "1"
      say_with_time "Backfill existing chatbots.chat_body_version to 1.0" do
        execute "UPDATE chatbots SET chat_body_version = '1.0'"
      end
    end
  end

  def down
    return unless column_exists?(:chatbots, :chat_body_version)

    change_column_default :chatbots, :chat_body_version, "2.0"
  end
end
