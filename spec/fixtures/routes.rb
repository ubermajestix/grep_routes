# This is psuedo-real routes file that has lots of fun stuff like scopes and
# namespaces, resources and named routes as well as conditional logic based on
# the Rails.env.
SomeRailsApp::Application.routes.draw do
  
  resource :user_session, only: [ :create, :new, :destroy ]

  
  namespace :admin do
    
    resources :companies do
    end
    
    resources :employees, only: [:index] do
       member do
         put :revoke_access
       end
     end
  end
  
  resources :vacation do
    get :home
    get :store
    member do
      get :discussion
    end
    match 'profile_edit'   => 'profiles#edit'
    match 'profile_update' => 'profiles#update'
    get :settings
    post :settings
  end
  
  resources :subscriptions, :only => [:index, :update]
  
  match 'login'                   => 'user_sessions#new'
  match 'logout'                  => 'user_sessions#destroy'
  match 'home'                    => 'companies#home'
  match 'forgot_password'         => 'password_resets#new'
  match 'activate/:token'         => 'activation#new', as: 'activate_account'
  
  scope ':nickname/:slug', as: 'customer' do
    match '/' => 'customer#show'
    match '/settings' => 'customer#settings'
    match '/ask_for_password' => 'customer#ask_for_password'
    match '/submit_password' => 'customer#submit_password', coditions: {method: :post}
    scope ':segment_slug', as: 'segment' do
      match 'photos/:id'  => 'photos#show',       :as => "photo_show"
      match 'posts/:id'   => 'posts#show',        :as => "post_show"
      match 'videos/:id'  => 'videos#show',       :as => "video_show"
      match 'details/:id' => 'triptrackers#show', :as => "detail_show"
    end
  end
  
  match 'privacy' => 'welcome#privacy'
  match 'terms'   => 'welcome#terms'
  
  root to: 'welcome#index'
  
  # if development, the url is concourse.dev, otherwise it's www. for production, and enviroment_name. for anything else
  default_url_options host: Rails.env.development? ? 'yoursite.dev': Rails.env.production? ? "www.example.com" : "#{ Rails.env }.example.com"
  
  
end
