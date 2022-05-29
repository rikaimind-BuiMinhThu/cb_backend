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
        resources :passwords
        resources :registrations
        resources :confirmations
      end
      namespace :managements do
        resources :users, except: [:new, :edit]
        resources :clients, except: [:new, :edit]
      end
      resources :clients, except: [:new, :edit]
    end
  end

  namespace :api do
    namespace :v1 do
      resources :sessions, only: :new
    end
  end
end
