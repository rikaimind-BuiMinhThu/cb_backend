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
        resources :instagram_user, only: [:index, :show]
      end
      namespace :message_managements do
        resources :message_groups, except: [:new, :edit]
        post "message_groups/:id/copy", :to => 'message_groups#copy'
        resources :message_bags, except: [:index, :new, :edit]
        post "message_bags/:id/copy", :to => 'message_bags#copy'
        resources :messages, except: [:index, :new, :edit]
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
