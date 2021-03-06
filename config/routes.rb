Rails.application.routes.draw do
  devise_for :users,
             controllers: {
               omniauth_callbacks: 'sessions'
             }

  devise_scope :user do
    get 'sign_out', to: 'sessions#destroy'
  end

  root 'application#index'
  get 'about', to: 'application#about'
  get 'api_documentation', to: 'application#api'
  get 'about_bip', to: 'application#about_bip'

  resources :submissions do
    member do
      patch :publish
      patch :revoke
    end
    resources :uploads, controller: 'submissions/uploads', only: [:new, :create, :destroy]
  end
  resources :depositions, only: [:new, :create]
  resources :plant_lines, only: [:index]
  resources :plant_varieties, only: [:index]
  resources :plant_parts, only: [:index]
  resources :plant_populations, only: [:index]
  resources :plant_trials, only: [:index, :show]
  resources :trait_descriptors, only: [:index]
  resources :traits, only: [:index]
  resources :trial_scorings, only: [:show]
  resources :data_tables, only: [:index, :show]
  resources :analyses, except: [:edit]

  namespace :analyses do
    resources :data_files, controller: 'data_files', only: [:new, :create, :destroy]
  end

  get 'search', to: 'searches#counts'
  get 'browse_data', to: 'data_tables#index', defaults: { model: 'plant_populations' }

  resource :api_keys, only: [:show] do
    member do
      put :recreate
    end
  end

  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      get_constraints = {
        plural_model_name: /#{Api.readable_models.map { |klass| klass.name.underscore.pluralize }.join("|")}/
      }

      post_constraints = {
        plural_model_name: /#{Api.writable_models.map { |klass| klass.name.underscore.pluralize }.join("|")}/
      }

      publishable_constraints = {
        plural_model_name: /#{Api.publishable_models.map { |klass| klass.name.underscore.pluralize }.join("|")}/
      }

      get ":plural_model_name", to: 'resources#index', constraints: get_constraints
      get ":plural_model_name/:id", to: 'resources#show', constraints: get_constraints
      post ":plural_model_name", to: 'resources#create', constraints: post_constraints
      delete ":plural_model_name/:id", to: 'resources#destroy', constraints: post_constraints
      patch ":plural_model_name/:id/publish", to: 'resources#publish', constraints: publishable_constraints
      patch ":plural_model_name/:id/revoke", to: 'resources#revoke', constraints: publishable_constraints
    end
  end
end
