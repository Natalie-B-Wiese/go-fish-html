Rails.application.routes.draw do
  resources :users, only: [:new, :create]
  get 'users/profile', to: "users#show"
  
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "games/history", to: "games#history"
  resources :games, only: [:index, :new, :create]
  
  post "games/:id/join", to: 'games#join', as: "join_game"
  post "games/:id/play", to: 'games#play', as: "play_turn"

  get "games/:id", to: 'games#show', as: "show_game"
  
  root 'games#index'

  get "pages/rules", to: "pages#rules"
  resources :pages, only: [:index]

  # Stats page ( stats#index ). Player stats (static/placeholder content for now), in a StatsController 
  resources :stats, only: [:index]  


  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
