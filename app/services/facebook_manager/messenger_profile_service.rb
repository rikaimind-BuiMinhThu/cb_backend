module FacebookManager
  class MessengerProfileService
    PLATFORM = 'instagram'.freeze

    def initialize(access_token)
      @client = GraphApiClient.new(access_token)
    end

    def ice_breakers_status
      @client.get('me/messenger_profile', fields: 'ice_breakers', platform: PLATFORM)
    end

    def publish_ice_breakers(call_to_actions)
      @client.post(
        'me/messenger_profile',
        {
          platform: PLATFORM,
          ice_breakers: [
            {
              call_to_actions: call_to_actions,
              locale: 'default'
            }
          ]
        },
        platform: PLATFORM
      )
    end

    def remove_ice_breakers
      @client.delete('me/messenger_profile', fields: "['ice_breakers']", platform: PLATFORM)
    end

    def persistent_menu_status
      @client.get('me/messenger_profile', fields: 'persistent_menu', platform: PLATFORM)
    end

    def publish_persistent_menu(call_to_actions)
      @client.post(
        'me/messenger_profile',
        {
          persistent_menu: [
            {
              locale: 'default',
              call_to_actions: call_to_actions
            }
          ]
        },
        platform: PLATFORM
      )
    end

    def remove_persistent_menu
      @client.delete('me/messenger_profile', fields: "['persistent_menu']", platform: PLATFORM)
    end
  end
end
