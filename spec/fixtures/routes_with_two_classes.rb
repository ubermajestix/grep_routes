SomeRailsApp::Application.routes.draw do
  resources :user
  mount Someapp, at: '/some/app'
  mount Another::App.server!, at: '/another'
end