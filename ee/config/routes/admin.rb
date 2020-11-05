# frozen_string_literal: true

namespace :admin do
  resources :users, only: [], constraints: { id: %r{[a-zA-Z./0-9_\-]+} } do
    member do
      post :reset_runners_minutes
    end
  end

  scope(path: 'groups/*id',
        controller: :groups,
        constraints: { id: Gitlab::PathRegex.full_namespace_route_regex, format: /(html|json|atom)/ }) do
    scope(as: :group) do
      post :reset_runners_minutes
    end
  end

  resource :push_rule, only: [:show, :update]
  resource :email, only: [:show, :create]
  resources :audit_logs, controller: 'audit_logs', only: [:index]
  resources :audit_log_reports, only: [:index], constraints: { format: :csv }
  resources :credentials, only: [:index, :destroy] do
    member do
      put :revoke
    end
  end

  resource :license, only: [:show, :new, :create, :destroy] do
    get :download, on: :member

    resource :usage_export, controller: 'licenses/usage_exports', only: [:show]
  end

  # using `only: []` to keep duplicate routes from being created
  resource :application_settings, only: [] do
    get :seat_link_payload
    match :templates, via: [:get, :patch]
    get :geo, to: "geo/settings#show"
  end

  namespace :geo do
    get '/' => 'nodes#index'

    # Old Routes Replaced in 13.0
    get '/projects', to: redirect(path: 'admin/geo/replication/projects')
    get '/uploads', to: redirect(path: 'admin/geo/replication/uploads')
    get '/designs', to: redirect(path: 'admin/geo/replication/designs')

    resources :nodes, only: [:index, :create, :new, :edit, :update]

    scope '/replication' do
      get '/', to: redirect(path: 'admin/geo/replication/projects')

      resources :projects, only: [:index, :destroy] do
        member do
          post :reverify
          post :resync
          post :force_redownload
        end

        collection do
          post :reverify_all
          post :resync_all
        end
      end

      resources :designs, only: [:index]

      resources :uploads, only: [:index, :destroy]

      get '/:replicable_name_plural', to: 'replicables#index', as: 'replicables'
    end

    resource :settings, only: [:show, :update]
  end

  namespace :elasticsearch do
    post :enqueue_index
    post :trigger_reindexing
    post :cancel_index_deletion
  end
end
