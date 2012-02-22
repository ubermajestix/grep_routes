Concourse::Application.routes.draw do

  match '/facebook/:action'       => 'facebook', as: 'facebook'

  if Rails.env.development?
    mount Preview::ErrorMailer => 'mail_view/error_mailer' # Use this to test emails in browser, go to root/mail_view
    mount Preview::UserMailer  => 'mail_view/user_mailer'
    mount Preview::StoreMailer  => 'mail_view/store_mailer'
    mount Preview::BrandMailer  => 'mail_view/brand_mailer'
  end

  resources :users, only: [:update]
end