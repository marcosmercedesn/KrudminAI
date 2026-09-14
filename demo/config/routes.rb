Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  resource :session, only: %i[new create destroy]
  resources :tickets do
    patch :restore, on: :member
    post "actions/:action_name", on: :member, to: "tickets#perform_action", as: :action
    post "bulk_actions/:action_name", on: :collection, to: "tickets#perform_bulk_action", as: :bulk_action
  end
  resources :locations
  resources :vendors
  resources :assets, path: "operations/assets" do
    get "lookup/:field_name", on: :collection, to: "assets#lookup_field", as: :lookup_field
  end
  get "dashboard", to: "dashboard#show"
  get "dashboard/refresh", to: "dashboard#refresh", as: :dashboard_refresh
  get "companion", to: "companion#show"
  post "companion", to: "companion#create"

  root "tickets#index"
end
