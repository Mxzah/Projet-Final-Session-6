# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  root to: "angular#index"

  namespace :api, constraints: { format: "json" } do
    resources :tables, only: %i[index create update destroy] do
      member do
        patch :mark_cleaned
      end
      resources :availabilities, only: %i[index create update destroy],
                                 controller: "table_availabilities"
    end
    get "tables/:qr_token", to: "tables#show"
    get "tables/:qr_token/qr_code", to: "tables#qr_code"

    resources :categories, only: %i[index create update destroy] do
      collection do
        patch :reorder
      end
      resources :availabilities, only: %i[index create update destroy],
                                 controller: "category_availabilities"
    end
    resources :items, only: %i[index show create update destroy] do
      collection do
        get :stats
      end
      member do
        delete :hard, action: :hard_destroy
        patch :restore, action: :restore
      end
      resources :availabilities, only: %i[index create update destroy],
                                 controller: "item_availabilities"
    end
    resources :combos, only: %i[index create] do
      resources :availabilities, only: %i[index create update destroy],
                                 controller: "combo_availabilities"
    end
    resources :combo_items, only: %i[index create destroy]
    resources :users, only: %i[index show create update destroy]
    resources :reviews, only: %i[index show create update destroy]

    resources :orders, only: %i[index show create update destroy] do
      collection do
        get :stats
      end
      resources :order_lines, only: %i[index create update destroy]
      post "order_lines/send_lines", to: "order_lines#send_lines"
      member do
        post :pay
      end
    end
    post "orders/close_open", to: "orders#close_open"

    get "waiters/assigned", to: "waiters#assigned"

    get "current_user", to: "sessions#show"

    resources :vibes, only: %i[index create update destroy] do
      member do
        patch :restore
      end
    end
    get "kitchen/orders", to: "cuisine#orders"
    post "kitchen/orders/:id/release", to: "cuisine#release_order"
    post "kitchen/orders/:id/assign_server", to: "cuisine#assign_server"
    patch "kitchen/order_lines/:id/next_status", to: "cuisine#next_status"
    patch "kitchen/order_lines/:id", to: "cuisine#update_line"
    delete "kitchen/order_lines/:id", to: "cuisine#destroy_line"

    # Server (waiter) dashboard
    get "server/tables", to: "server#tables"
    get "server/orders", to: "server#orders"
    post "server/orders/:id/assign", to: "server#assign"
    post "server/orders/:id/release", to: "server#release"
    post "server/orders/:id/clean", to: "server#clean"
    delete "server/orders/:id/cancel", to: "server#cancel"
    patch "server/order_lines/:id/serve", to: "server#serve_line"
    patch "server/order_lines/:id", to: "server#update_line"
    delete "server/order_lines/:id", to: "server#destroy_line"
  end

  match "*url", to: "angular#index", via: :get
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
