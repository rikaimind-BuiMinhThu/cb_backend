Rails.application.routes.draw do
  devise_for :users, :skip => :sessions, :controllers => {
    :passwords => "api/v1/users/passwords",
    :omniauth_callbacks => "users/omniauth_callbacks"
  }
  # root "articles#index"
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      post "sign_in", :to => 'sessions#create'
      post "refresh_token", :to => 'tokens#create'
      namespace :users do
        resources :registrations
        resources :omniauth_callbacks
        post "/auth/facebook/callback" => "omniauth_callbacks#facebook"
      end
      namespace :managements do
        resources :users, except: [:new, :edit]
        resources :clients, except: [:new, :edit]
        get "/get_client_with_name" => "clients#get_client_with_name"
        resources :instagram_users, only: [:index, :show, :update]
        resources :chatbots, except: [:new, :edit] do
          resources :variables, except: [:new, :edit]
          resources :scenarios, except: [:new, :edit]
          get "scenarios/:id/conversation", :to => 'scenarios#detail_conversation'
          post "scenarios/:id/conversation", :to => 'scenarios#conversation'
          post "scenarios/:id/duplicate", :to => 'scenarios#duplicate'
          get "scenarios/:id/preview", :to => 'scenarios#preview'
        end
        post "chatbots/:id/duplicate", :to => 'chatbots#duplicate'
        post "chatbots/:id/scenario_selected", :to => 'chatbots#scenario_selected'
        get "chatbots/:chatbot_id/all_scenarios", :to => 'scenarios#get_all'
        get "chatbots/:chatbot_id/get_scenario_selected", :to => 'scenarios#get_scenario_selected'
        get "chatbots/:id/design_settings", :to => 'chatbots#get_design_settings'
        post "chatbots/:id/design_settings", :to => 'chatbots#update_design_settings'
        get "chatbots/:id/chat_body_version", :to => 'chatbots#chat_body_version'
        get "chatbots/:id/sdk", :to => 'chatbots#webchat_sdk'
        get "chat_log/statistic", :to => 'chat_log#statistic'
        get "chat_log/:bot_id/list", :to => 'chat_log#index'
        get "chat_log/:sc_id/:user_id", :to => 'chat_log#show'
        get "get_list_chatbot_by_client", :to => 'chatbots#get_list_chatbot_by_client'
        get "get_list_scenario_by_client", :to => 'scenarios#get_list_scenario_by_client'
        resources :user_chatbots, only: [:index, :create, :update, :destroy]
        resources :emails, only: [:index, :create, :show, :update, :destroy]
        post "/emails/:id/duplicate" => "emails#duplicate"
        get "/get_list_emails_by_chatbot" => "emails#get_list_emails_by_chatbot"
        post "/emails/:id/send_email" => "emails#send_email"
        post "/contact_forms/send" => "contact_forms#send_inquiry"
        resources :client_emails, only: [:index, :create, :update, :destroy]
        resources :file, only: [:index, :create, :destroy]
        post "/file/upload" => "file#presinged_aws"
        resources :push_message_histories, only: [:index]
        patch "push_messages/:id/subscribe" => "push_messages#subscribe"
        patch "push_messages/:id/unsubscribe" => "push_messages#unsubscribe"
        resources :history_click_urls, only: [:index, :create, :show, :update, :destroy]
        resources :sms_templates, only: [:index, :create, :show, :update, :destroy]
        resources :plans, only: [:index, :show, :update, :create, :destroy]
        resources :payment_histories, only: [:show, :update, :create, :destroy]
        resources :scenario_templates, only: [:index, :show, :create, :destroy]
        get "scenario_templates/:id/conversation", :to => "scenario_templates#detail_conversation"
        post "scenario_templates/:id/conversation", :to => "scenario_templates#conversation"
        resources :order_confirm_message_templates, only: [:index, :show, :create, :update, :destroy]
      end
      namespace :message_managements do
        get "message_groups/data_analyst", :to => 'message_groups#data_analyst'
        resources :message_groups, except: [:new, :edit]
        post "message_groups/:id/copy", :to => 'message_groups#copy'
        get "message_groups/:id/export_csv", :to => 'message_groups#export_csv'
        resources :message_bags, except: [:index, :new, :edit]
        post "message_bags/:id/copy", :to => 'message_bags#copy'
        post "message_bags/:id/move", :to => 'message_bags#move'
        resources :messages, except: [:index, :new, :edit]
        post "messages/:id/move", :to => 'messages#move'
        resources :ice_breakers, except: [:new, :edit]
        get "/ice_breakers_status" => "ice_breakers#status"
        get "/ice_breakers_turn_on" => "ice_breakers#turn_on"
        get "/ice_breakers_turn_off" => "ice_breakers#turn_off"
        resources :persistent_menus, except: [:new, :edit]
        get "/persistent_menus_status" => "persistent_menus#status"
        get "/persistent_menus_turn_on" => "persistent_menus#turn_on"
        get "/persistent_menus_turn_off" => "persistent_menus#turn_off"
        resources :keyword_settings, except: [:new, :edit]
        get "/keyword_settings_active" => "keywords#active"
        resources :hot_templates, except: [:new, :edit, :show]
      end
      namespace :instagram_users do
        resources :custom_items, except: [:index, :new, :edit]
        resources :labels, except: [:index, :new, :edit]
        resources :conversions, only: [:index, :create, :show]
        resources :supporting_users, only: :destroy
      end
      resources :instagram_settings, only: [:index, :show, :update, :destroy]
      get "webhook", :to => 'chatbots#webhook'
      post "webhook", :to => 'chatbots#webhook_callback'
      post "instagram_connect", :to => 'instagram_settings#connect'
      post "logout_fb", :to => 'instagram_settings#logout_fb'
      patch "instagram_setting_change_status/:id", :to => 'instagram_settings#change_status'
      namespace :analytics do
        resources :users, only: :index
        resources :chatbot_usages, only: :show
        resources :scenario_counts, only: [:show, :update]
        get "scenario_counts/:id/download" => "scenario_counts#download"
        resources :scenario_pages, only: [:create]
      end
      resources :prefectures, only: :index
      get "cities", :to => 'prefectures#get_cities'
      get "towns", :to => 'prefectures#get_towns'
      get "get_address_from_zip_code", :to => 'prefectures#get_address_from_zip_code'
      post "jp_convert", :to => 'jp_convert#convert'
      namespace :payment_managements do
        resources :payment_gateways, except: [:new, :edit]
        resources :payment_managements, only: :show
        patch "payment_managements/:id/update_consumption_tax" => "payment_managements#update_consumption_tax"
        patch "payment_managements/:id/update_specify_payment_gateway" => "payment_managements#update_specify_payment_gateway"
        patch "payment_managements/:id/update_settlement_fee" => "payment_managements#update_settlement_fee"
        patch "payment_managements/:id/update_shipping_fee" => "payment_managements#update_shipping_fee"
        patch "payment_managements/:id/update_np_deferred_payment" => "payment_managements#update_np_deferred_payment"
      end
      namespace :chatbot_settings do
        resources :withdrawal_preventions, only: [:show, :update]
      end
      namespace :scenario_users do
        resources :scenario_user_responses, only: [:create] do
          collection do
            post :create_order
          end
        end
        resources :conversions, only: [:create]
        resources :scenario_user_responses_status, only: [:create] do
          collection do
            patch :update
          end
        end
        resources :scenario_user_responses_message, only: [:create]
        post "entry", to: "scenario_users#entry"
      end
      get '/shopify/product_variants', to: 'shopify#product_variants'
      get '/shopify/product_variant', to: 'shopify#product_variant'
      post '/shopify/cart_create', to: 'shopify#cart_create'
      post '/shopify/cart_lines_add', to: 'shopify#cart_lines_add'
      post '/shopify/webhook', to: 'shopify#webhook'
    end
  end
end
