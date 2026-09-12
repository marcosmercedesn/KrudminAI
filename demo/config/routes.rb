Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  resource :session, only: %i[new create destroy]
  resources :tickets
  get "dashboard", to: "dashboard#show"
  get "companion", to: "companion#show"
  post "companion", to: "companion#create"

  root "tickets#index"
end
