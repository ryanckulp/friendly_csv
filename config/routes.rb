Rails.application.routes.draw do
  root 'pages#home'

  get 'batches/preview/:id', to: "batches#preview", as: 'batch_preview'
  get 'batches/preview/:id/progress', to: "batches#progress", as: 'batch_progress'
  resources :batches

  post 'import', to: "leads#import", as: 'import_leads'
  resources :leads

  devise_for :users, :controllers => {:registrations => "registrations"}
  devise_scope :user do
    get 'start', to: "registrations#start", as: 'start'
    get 'signup', to: "registrations#new", as: 'signup'
    get 'login', to: "sessions#new", as: 'login'
    get 'settings', to: "registrations#edit", as: 'settings'
    delete 'logout', to: "sessions#destroy", as: 'logout'
  end

end
