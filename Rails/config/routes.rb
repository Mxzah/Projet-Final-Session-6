Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  root to: "angular#index"

  namespace :api, constraints: { format: 'json' } do
    resources :tables, only: [:index, :create], param: :qr_token
    get 'tables/:qr_token', to: 'tables#show'
    get 'tables/:qr_token/qr_code', to: 'tables#qr_code'

    get 'current_user', to: 'sessions#current_user'
  end

  match '*url', to: "angular#index", via: :get
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
