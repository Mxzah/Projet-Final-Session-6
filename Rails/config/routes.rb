Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  root to: "angular#index"

  namespace :api, constraints: { format: 'json' } do
    # Add your API resources here
  end

  match '*url', to: "angular#index", via: :get
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
