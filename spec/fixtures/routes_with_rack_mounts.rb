YourApp::Application.routes.draw do

  resources :users, only: [:update]
  
  match '/facebook/:action'       => 'facebook', as: 'facebook'

  if Rails.env.development?
    # These are little Rack apps we defined somewhere in our Rails app.
    # For our purposes here, we don't care what they do, we just have to define
    # #call on them to statisfy the router.
    # 
    # See the mail_view gem for previewing your mailer views in the browser.
    mount Preview::ErrorMailer => 'mail_view/error_mailer' 
    mount Preview::UserMailer  => 'mail_view/user_mailer'
    mount Preview::StoreMailer  => 'mail_view/store_mailer'
    mount Preview::BrandMailer  => 'mail_view/brand_mailer'
  end
  
  # Some Rack apps in routes.rb files from projects github
  
  mount Tolk::Engine => "/tolk"
  mount Evergreen.rails, :at => '/evergreen'
  mount WebsocketApp, :at => '/socket'
  mount SinatraInternal => '/sinatra'
  mount Gitstats::Shitometer => '/gitstats'
  mount Server.new, at: "/server/new"
  
  # And a made up Rack app
  mount Nested::RackApp.app, at: '/nested/rackapp'
end