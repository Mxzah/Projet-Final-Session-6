Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  root to: "angular#index"

  namespace :api, constraints: { format: 'json' } do
    resources :tables, only: [:index, :create, :update, :destroy] do
      member do
        patch :mark_cleaned
      end
      resources :availabilities, only: [:index, :create, :update, :destroy],
                controller: 'table_availabilities'
    end
    get 'tables/:qr_token', to: 'tables#show'
    get 'tables/:qr_token/qr_code', to: 'tables#qr_code'

    resources :categories, only: [:index, :create, :update, :destroy]
    resources :items, only: [:index, :show, :create, :update, :destroy] do
      member do
        delete :hard, action: :hard_destroy
        put :restore, action: :restore
      end
      resources :availabilities, only: [:index, :create, :update, :destroy]
    end
    resources :combos, only: [:index, :create]
    resources :combo_items, only: [:index, :create]
    resources :users, only: [:index, :show, :create, :update, :destroy]

    resources :orders, only: [:index, :show, :create, :update, :destroy] do
      resources :order_lines, only: [:index, :create, :update, :destroy]
      member do
        post :pay
      end
    end
    post 'orders/close_open', to: 'orders#close_open'

    get 'waiters/assigned', to: 'waiters#assigned'

    get 'current_user', to: 'sessions#current_user'

    resources :vibes, only: [:index]
    get 'kitchen/orders', to: 'cuisine#orders'
    put 'kitchen/order_lines/:id/next_status', to: 'cuisine#next_status'
    put 'kitchen/order_lines/:id', to: 'cuisine#update_line'
    delete 'kitchen/order_lines/:id', to: 'cuisine#destroy_line'
  end

  match '*url', to: "angular#index", via: :get
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
