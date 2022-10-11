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
        resources :instagram_users, only: [:index, :show, :update]
        resources :chatbots, except: [:new, :edit] do
          resources :variables, except: [:new, :edit]
          resources :scenarios, except: [:new, :edit]
          get "scenarios/:id/conversation", :to => 'scenarios#detail_conversation'
          post "scenarios/:id/conversation", :to => 'scenarios#conversation'
          post "scenarios/:id/duplicate", :to => 'scenarios#duplicate'
        end
        post "chatbots/:id/duplicate", :to => 'chatbots#duplicate'
        post "chatbots/:id/scenario_selected", :to => 'chatbots#scenario_selected'
        resources :user_chatbots, only: [:create, :update, :destroy]
        resources :emails, only: [:index, :create, :show, :update, :destroy]
        post "/emails/:id/duplicate" => "emails#duplicate"
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
      patch "instagram_setting_change_status/:id", :to => 'instagram_settings#change_status'
      namespace :analytics do
        resources :users, only: :index
        resources :chatbot_usages, only: :show
      end
    end
  end
end
