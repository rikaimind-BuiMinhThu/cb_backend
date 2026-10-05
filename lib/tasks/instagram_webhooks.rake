namespace :instagram do
  desc 'Verify Instagram webhook setup: staging URL, Page subscribed_apps, Meta Dashboard checklist'
  task verify_webhooks: :environment do
    app_id = Settings.facebook.meta_app.app_id
    verify_token = Settings.webhook.verify_token
    webhook_url = ENV.fetch('WEBHOOK_URL', 'https://ec-chatbot-test.com/api/v1/webhook')

    puts '=== Instagram Webhook Verification ==='
    puts "App ID: #{app_id}"
    puts "Webhook URL: #{webhook_url}"
    puts "Verify token: #{verify_token[0, 8]}..."
    puts

    # 1. Callback URL challenge
    challenge = 'instagram_webhook_verify'
    uri = URI("#{webhook_url}?hub.mode=subscribe&hub.verify_token=#{verify_token}&hub.challenge=#{challenge}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    response = http.get(uri.request_uri)
    if response.code == '200' && response.body == challenge
      puts '[OK] Webhook verification challenge'
    else
      puts "[FAIL] Webhook verification challenge (HTTP #{response.code}, body=#{response.body.inspect})"
    end
    puts

    # 2. Page subscribed_apps per connected account
    accounts = InstagramAccount.where.not(page_access_token: [nil, ''])
    if accounts.empty?
      puts '[WARN] No Instagram accounts with page_access_token — reconnect via 選択 first'
    else
      accounts.find_each do |acc|
        puts "Account id=#{acc.id} ig_id=#{acc.ig_id} page_id=#{acc.page_id}"
        result = FacebookManager::GraphApiClient.new(acc.page_access_token).get("#{acc.page_id}/subscribed_apps")
        if result[:success]
          data = result[:data]
          fields = data.is_a?(Hash) ? data.dig('data', 0, 'subscribed_fields') : nil
          puts "  [OK] subscribed_apps: #{fields || data.inspect}"
        else
          msg = result.dig(:error, :message) || result.inspect
          puts "  [FAIL] subscribed_apps: #{msg}"
        end
        puts "  post_comment_bag_status=#{acc.post_comment_bag_status} default_reply_bag_id=#{acc.default_reply_bag_id}"
      end
    end
    puts

    # 3. Meta Dashboard checklist (manual steps)
    puts '=== Meta Dashboard checklist (manual) ==='
    puts 'Use cases → Permissions (Ready for testing):'
    %w[
      pages_show_list pages_read_engagement pages_manage_metadata pages_messaging
      instagram_basic instagram_manage_messages instagram_manage_comments business_management
    ].each { |p| puts "  - #{p}" }
    puts
    puts 'Webhooks → Instagram object: comments, messages, messaging_postbacks'
    puts 'Webhooks → Page object: messages, messaging_postbacks'
    puts 'App roles → Add personal IG account as Instagram Tester'
    puts
    puts 'Full guide: docs/instagram-webhook-setup.md'
  end
end
